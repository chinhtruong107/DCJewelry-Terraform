output "instance_ip_addr_public" {
  value = module.compute.instance_ip_addr_public
}

output "instance_ip_addr_private" {
  value = module.compute.instance_ip_addr_private
}

output "control_node_public_ip" {
  value = module.compute.control_node_public_ip
}

output "backend_private_ip" {
  value = module.compute.backend_private_ip
}

output "pmm_private_ip" {
  value = module.monitoring.private_ip
}

output "rds_endpoint" {
  value = module.database.endpoint
}

output "sns_alert_topic_arn" {
  value       = module.observability.alert_topic_arn
  description = "SNS topic to use as the target of CloudWatch alarms."
}

output "telegram_alerts_enabled" {
  value       = nonsensitive(module.observability.telegram_alerts_enabled)
  description = "True when SNS alerts are forwarded to the configured Telegram chat."
}
