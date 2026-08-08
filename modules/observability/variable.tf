variable "alert_topic_name" {
  description = "Name of the SNS topic used by CloudWatch alarms."
  type        = string
  default     = "dcjewelry-infrastructure-alerts"
}

variable "log_retention_days" {
  description = "Retention period for EC2 CloudWatch logs."
  type        = number
  default     = 30
}

variable "telegram_bot_token" {
  description = "Telegram Bot API token. Keep it only in the ignored terraform.tfvars file."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "telegram_chat_id" {
  description = "Telegram user or group chat ID that receives alerts."
  type        = string
  default     = null
  nullable    = true
}

variable "ec2_instances" {
  description = "Named EC2 instance IDs to monitor."
  type        = map(string)
}

variable "database_identifier" {
  description = "RDS DB instance identifier to monitor."
  type        = string
}

variable "cpu_threshold_percent" {
  type        = number
  description = "EC2 and RDS CPU alarm threshold."
}

variable "memory_threshold_percent" {
  type        = number
  description = "CloudWatch Agent memory-used alarm threshold."
}

variable "disk_threshold_percent" {
  type        = number
  description = "CloudWatch Agent root-disk-used alarm threshold."
}

variable "rds_free_storage_gib" {
  type        = number
  description = "RDS free storage alarm threshold in GiB."
}
