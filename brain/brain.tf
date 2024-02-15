terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0", 
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.aws_profile
}

# Get mgmt subnet object
data "aws_subnet" "management_subnet" {
  filter {
    name = "subnet-id"
    values = [var.management_subnet]
  }
}

# Create SG for the brain management interface
resource "aws_security_group" "management_sg" {
  name = "${var.base_name}-mgtsecgroup"
  description = "Management security group for ${var.base_name}"
  vpc_id = data.aws_subnet.management_subnet.vpc_id

  ingress {
    description      = "TLS from Management subnet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [data.aws_subnet.management_subnet.cidr_block]
  }

  ingress {
    description      = "SSH from Management subnet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [data.aws_subnet.management_subnet.cidr_block]
  }
  # Allow all as there is a long list of required endpoints
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Create the management NIC
resource "aws_network_interface" "vectra_brain_mgmt" {
  subnet_id = data.aws_subnet.management_subnet.id
  private_ips = ["${var.management_ip}"]
  security_groups = [aws_security_group.management_sg.id]
}

# Create Brain instance
resource "aws_instance" "vectra_brain" {
  ami = var.brain_ami
  instance_type = var.brain_instance_type
  user_data = base64encode("{\"provision-token\":\"${var.provision_token}\",\"backup-token\":\"${var.brain_backup_token}\"}")
  key_name = var.ssh_key
  tenancy = var.tenancy

  ebs_block_device {
    device_name = "/dev/sda1"
    delete_on_termination = true
    volume_size = 256
    volume_type = "gp2"
  }
    
  ebs_block_device {
    device_name = "/dev/sdb"
    delete_on_termination = true
    volume_size = 256
    volume_type = "gp2"
  }
  
  ebs_block_device {
    device_name = "/dev/sdc"
    delete_on_termination = true
    volume_size = 256
    volume_type = "gp2"
  }
  
  ebs_block_device {
    device_name = "/dev/sdd"
    delete_on_termination = true
    volume_size = 64
    volume_type = "gp2"
  }

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.vectra_brain_mgmt.id
  }

  tags = {
    Name = var.base_name
  }
}

output "brain_ip" {
  value = aws_network_interface.vectra_brain_mgmt.private_ip
}

output "management_sg" {
  value = aws_security_group.management_sg.arn
}