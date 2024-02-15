terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.aws_profile
}

# Get traffic subnet object
data "aws_subnet" "traffic_subnet" {
  filter {
    name = "subnet-id"
    values = [var.traffic_subnet]
  }
}

# Get traffic VPC from  subnet object
data "aws_vpc" "traffic_vpc" {
  id = data.aws_subnet.traffic_subnet.vpc_id
}

# Get management subnet object
data "aws_subnet" "management_subnet" {
  filter {
    name = "subnet-id"
    values = [var.management_subnet]
  }
}

# Create SG for management interfacce
resource "aws_security_group" "management_sg" {
  name = "${var.base_name}-mgtsecgroup"
  description = "Management security group for ${var.base_name}"
  vpc_id = data.aws_subnet.management_subnet.vpc_id

  ingress {
    description = "TLS from Brain (health check) "
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.brain_ip}/32"]
  }

  ingress {
    description = "SSH from Management Brain (debugging needs)"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.brain_ip}/32"]
  }

  egress {
    description = "TLS to Brain (health reporting API)"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.brain_ip}/32"]
  }

  egress {
    description = "SSH to Brain (metadata tunnel)"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.brain_ip}/32"]
  }
}

# Create SG for traffic interface
resource "aws_security_group" "traffic_sg" {
  name = "${var.base_name}-trafficsecgroup"
  description = "Management security group for ${var.base_name}"
  vpc_id = data.aws_subnet.management_subnet.vpc_id

  ingress {
    description = "VXLAN from VPC"
    from_port = 4789
    to_port = 4789
    protocol = "udp"
    cidr_blocks = [data.aws_vpc.traffic_vpc.cidr_block]
  }

  egress {
    description = "Needed for initial setup, can be deleted once sensor is paired"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.brain_ip}/32"]
  }
}

# Create management interface and link it to corresponding SG
resource "aws_network_interface" "vectra_sensor_mgmt" {
  subnet_id = data.aws_subnet.management_subnet.id
  private_ips = ["${var.management_ip}"]
  security_groups = [aws_security_group.management_sg.id]
}

# Create traffic interface and link it to corresponding SG
resource "aws_network_interface" "vectra_sensor_traffic" {
  subnet_id = data.aws_subnet.traffic_subnet.id
  private_ips = ["${var.traffic_ip}"]
  security_groups = [aws_security_group.traffic_sg.id]
}

# Create sensor instance
resource "aws_instance" "vectra_sensor" {
  ami = local.region_map[var.region]
  instance_type = var.sensor_instance_type
  user_data = base64encode("{\"vectra-mode\":\"sensor\",\"lb_arn\":\"${aws_lb.sensor_nlb.arn}\",\"brain-ip\":\"${var.brain_ip}\",\"registration_token\": \"${var.registration_token}\"}")
  key_name = var.ssh_key
  tenancy = var.tenancy
  ebs_block_device {
    device_name = "/dev/sda1"
    delete_on_termination = true
    volume_size = 50
    volume_type = "gp2"
  }
  ebs_block_device {
    device_name = "/dev/sdb"
    delete_on_termination = true
    volume_size = local.data_disk_size_map[var.sensor_instance_type]
    volume_type = "gp2"
  }
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.vectra_sensor_traffic.id
  }
   network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.vectra_sensor_mgmt.id
  }
  tags = {
    Name = var.base_name
  }
}

#Create NLB to fron the sensor, allowing >10 mirror sessions
resource "aws_lb" "sensor_nlb" {
  name = "${var.base_name}-nlb"
  internal = true
  load_balancer_type = "network"
  subnets = [data.aws_subnet.traffic_subnet.id]
}

#Create a LB target group to put sensor into
resource "aws_lb_target_group" "lb_target" {
  name = "${var.base_name}-target-group"
  port = 4789
  protocol = "UDP"
  vpc_id = data.aws_vpc.traffic_vpc.id
  health_check{
    enabled = true
    healthy_threshold = 2
    interval = 30
    port = 80
    protocol = "TCP"
    # timeout = 10 (default, can't be changed)
    unhealthy_threshold = 2

  }
  stickiness {
    enabled = true
    type = "source_ip"
  }

}

# Attach sensor instance to target group
resource "aws_lb_target_group_attachment" "lb_target_attachment" {
  target_group_arn = aws_lb_target_group.lb_target.arn
  target_id = aws_instance.vectra_sensor.id
}

# Create listener for NLB on port 4789/UDP (VXLAN)
resource "aws_lb_listener" "sensor_nlb_listener" {
  load_balancer_arn = aws_lb.sensor_nlb.arn
  port = 4789
  protocol = "UDP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target.arn
  }
}