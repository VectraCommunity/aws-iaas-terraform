variable region {
  type = string
  description = "Region to deploy in"
}
variable base_name{
  type = string
  description = "The base appliance name to use for the instance and its associated resources."
}
variable brain_backup_token{
    type = string
    description = "If this is a Backup Brain, enter backup token of master brain."
     validation {
       condition = can(regex("^[0-9a-f]{40}$|^$", var.brain_backup_token))
       error_message = "Must be a valid backup token."
     }
    default = ""
}
variable brain_instance_type{
    type = string
    description = "Vectra Brain EC2 instance type."
    validation {
        condition     = can(regex("^r5d\\.[2,4,8]xlarge$", var.brain_instance_type))
        error_message = "Sensor appliance size must be either r5(n).large, r5(n).xlarge, r5(n).2xlarge, r5(n).4xlarge or c5n.18xlarge."
        }
}
variable provision_token {
    type = string
    description = "Vectra Provisioning token for licensing."
    validation {
      condition = can(regex("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$", var.provision_token))
      error_message = "Must be a valid provisioning token."
    }
}
variable ssh_key {
  type = string
  description = "SSH KeyPair name to ssh in the instance as vectra user"
}
variable management_ip{
    type = string
    description = "Private Management IP address to assume on launch (leave empty to use DHCP)"
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
variable brain_ami {
  type = string
  description = "brain ami white listed for your aws account"
}