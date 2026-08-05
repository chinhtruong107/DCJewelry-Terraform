variable "config" {
  description = "EC2 configuration."
  type = object({
    image_id      = string
    instance_type = string
    key_name      = string
    keypair_path  = string
  })
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

variable "subnet_id_control" {
  type        = string
  description = "The Control Node subnet ID to launch in"
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

variable "security_group_control" {
  type     = list(string)
  nullable = false
}
