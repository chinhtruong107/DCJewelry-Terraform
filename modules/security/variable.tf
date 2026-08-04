variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "vpc_id" {
  type        = string
  description = "The VPC ID"
  nullable    = false

}

variable "control_node_cidr" {
  type        = string
  description = "Public IPv4 CIDR allowed to SSH to the Control Node."
  nullable    = false
}
