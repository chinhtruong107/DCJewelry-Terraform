variable "region" {
  type    = string
  default = "ap-southeast-1"
}
#parameters for networking module
variable "availability_zone_1" {
  type     = string
  nullable = false
}
variable "availability_zone_2" {
  type     = string
  nullable = false
}
variable "cidr_block" {
  type     = string
  nullable = false
}
variable "public_subnet_ips" {
  type     = list(string)
  nullable = false

}
variable "private_subnet_ips" {
  type     = list(string)
  nullable = false
}

#parameter for compute module
variable "instance_type" {
  type        = string
  description = "Type of EC2 instance to launch. Example: t2.micro"
  default     = "t3.micro"
}
variable "amis" {
  type = map(string)
  default = {
    "ap-southeast-1" : "ami-0532913178263be11"
    "ap-northeast-1" : "ami-0126975fb247bf2e7"
  }
}
variable "keypair_path" {
  type    = string
  default = "./keypair/key.pub"
}

variable "control_node_cidr" {
  type        = string
  description = "Public IPv4 CIDR allowed to SSH to the Control Node, for example 203.0.113.10/32."
  nullable    = false
}

variable "db_name" {
  type        = string
  description = "Name of the database to create in RDS."
  nullable    = false
}

variable "db_identifier" {
  type        = string
  description = "Unique identifier for the RDS instance."
  default     = "dcjewelry-database"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_engine_version" {
  type        = string
  description = "MySQL engine version for RDS."
  default     = "8.0"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class, for example db.t3.micro."
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated RDS storage in GiB."
  default     = 20
}

variable "db_storage_type" {
  type        = string
  description = "RDS storage type."
  default     = "gp3"
}

variable "db_multi_az" {
  type        = bool
  description = "Enable RDS Multi-AZ deployment."
  default     = false
}
