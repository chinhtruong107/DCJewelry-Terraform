variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
}
variable "key_name" {
  type        = string
  description = "name of the keypair to use for the instance"
  nullable    = false
}
variable "instance_type" {
  type        = string
  description = "Type of EC2 instance to launch. Example: t2.micro"
  default     = "t3.micro"
}

variable "subnet_id_frontend" {
  type        = string
  description = "The frontend subnet ID to launch in"
  nullable    = false
}

variable "subnet_id_backend" {
  type        = string
  description = "The backend subnet ID to launch in"
  nullable    = false
}

variable "security_group_public" {
  type     = list(string)
  nullable = false
}

variable "security_group_private" {
  type     = list(string)
  nullable = false
}
