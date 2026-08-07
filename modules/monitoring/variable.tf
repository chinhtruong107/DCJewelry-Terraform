variable "config" {
  description = "PMM EC2 configuration."
  type = object({
    image_id      = string
    instance_type = string
    key_name      = string
    volume_size   = number
  })
}

variable "subnet_id" {
  type        = string
  description = "Private subnet for the PMM Server."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the PMM Server."
}
