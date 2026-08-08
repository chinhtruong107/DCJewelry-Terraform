output "cloudwatch_agent_instance_profile_name" {
  value = aws_iam_instance_profile.cloudwatch_agent.name
}

output "alert_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "telegram_alerts_enabled" {
  value       = nonsensitive(local.telegram_enabled)
  description = "True when the Telegram Lambda subscription has been configured."
}
