variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "networking" {
  description = "VPC and subnet configuration."
  type = object({
    cidr_block         = string
    availability_zones = list(string)
    public_subnet_ips  = list(string)
    private_subnet_ips = list(string)
  })
}

variable "security" {
  description = "Security group configuration."
  type = object({
    control_node_cidr = string
  })
}

variable "compute" {
  description = "EC2 and SSH key-pair configuration."
  type = object({
    image_id      = string
    instance_type = string
    key_name      = string
    keypair_path  = string
  })
}

variable "database" {
  description = "RDS configuration."
  type = object({
    identifier        = string
    name              = string
    username          = string
    password          = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    storage_type      = string
    multi_az          = bool
  })
  sensitive = true
}
