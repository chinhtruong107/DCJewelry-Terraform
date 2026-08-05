variable "subnet_ids" {
  type = list(string)
}

variable "database_security_group_id" {
  type = string
}

variable "config" {
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
