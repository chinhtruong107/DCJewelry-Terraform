variable "vpc_id" {
  type        = string
  description = "The VPC ID"
  nullable    = false

}

variable "config" {
  description = "Security group configuration."
  type = object({
    control_node_cidr = string
  })
}
