locals{
    data_disk_size_map = {
        "r5.large" = "128"
        "r5n.large" = "128"
        "r5.xlarge" = "128"
        "r5n.xlarge" = "128"
        "r5.2xlarge" = "512"
        "r5n.2xlarge" = "512"
        "r5.4xlarge" = "512"
        "r5n.4xlarge" = "512"
        "c5n.18xlarge" = "128"
    }
}
locals {
      region_map = {
        ap-east-1 = "ami-0112e0878a11f0334"
        eu-south-1 = "ami-0385896df398abb65"
        af-south-1 = "ami-0901ece1433bd67e1"
        ap-northeast-1 = "ami-0c51f4730bd29dfce"
        ap-northeast-2 = "ami-052c42c680e7b8023"
        ap-northeast-3 = "ami-027f407b4ccc0bb4c"
        ap-south-1 = "ami-0a027070ba089e9d9"
        ap-southeast-1 = "ami-0252a3c8d98c4c360"
        ap-southeast-2 = "ami-0ee0a428b767bc1d8"
        ca-central-1 = "ami-0d07261a5f32deb72"
        eu-central-1 = "ami-0b8dbe5899c719a7e"
        eu-north-1 = "ami-0d8aada23b340eb9b"
        eu-west-1 = "ami-02c6e537fdb8f430f"
        eu-west-2 = "ami-09f051ff2762e53f0"
        eu-west-3 = "ami-07f01e4cf36c3e893"
        me-south-1 = "ami-0ad64566d81b39c28"
        sa-east-1 = "ami-05df052c18053f1b9"
        us-east-1 = "ami-0ebaa438072158474"
        us-east-2 = "ami-052b327f638b910b7"
        us-west-1 = "ami-005f10e99acfc69ae"
        us-west-2 = "ami-0dcbaad395e16494f"
        us-gov-west-1 = "ami-08d527be8bd15da46"
        us-gov-east-1 = "ami-03b3e8ce68d58a53b"
    }
}
variable region {
  type = string
  description = "Region to deploy in"
}
variable base_name{
  type = string
  description = "Prepend all sensor resources with this string"
}
variable brain_ip{
    type = string
    description = "IP of the Vectra brain to pair the sensor to"
    default = "10.0.0.31"
}
variable sensor_instance_type{
    type = string
    description = "Vectra Sensor EC2 instance type."
    validation {
        condition     = can(regex("^(r5n{0,1}\\.[2,4]?x?large|c5n\\.18xlarge)$", var.sensor_instance_type))
        error_message = "Sensor appliance size must be either r5(n).large, r5(n).xlarge, r5(n).2xlarge, r5(n).4xlarge or c5n.18xlarge."
        }
    default = "r5.large"
}
variable registration_token {
    type = string
    description = " Token for registration with headend, 32 letters long."
    validation {
      condition = length(var.registration_token) == 32
      error_message = "Invalid length registration token provided."
    }
}
variable ssh_key {
  type = string
  description = "SSH KeyPair name to ssh in the instance as vectra user"
}
variable management_ip{
    type = string
    default = ""
    description = "Private Management IP address to assume on launch (empty to use DHCP)"
}
variable management_security_group {
  type = string
  description = "Security group ID to put management interface in (null to create)"
  default = null
}
variable management_subnet {
  type = string
  description = "Management Subnet ID"
}
variable tenancy {
  type = string
  description = "Whether this machine should be on a dedicated VM"
  validation {
      condition     = can(regex("^(dedicated|default|host)$", var.tenancy))
      error_message = "Must be a valid tenancy option."
      }
  default = "default"

}
variable traffic_ip {
  type = string
  default = ""
  description = "Private Traffic IP address to assume on launch (empty to use DHCP)"
}
variable traffic_security_group {
  type = string
  description = "Security group ID to put traffic interface in (null to create)"
  default = null
}
variable traffic_subnet {
  type = string
  description = "Traffic Subnet ID"
}