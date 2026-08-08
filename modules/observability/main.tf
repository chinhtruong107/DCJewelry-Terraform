data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

locals {
  telegram_enabled = var.telegram_bot_token != null && trimspace(var.telegram_bot_token) != "" && var.telegram_chat_id != null && trimspace(var.telegram_chat_id) != ""
}

resource "aws_iam_role" "cloudwatch_agent" {
  name               = "dcjewelry-cloudwatch-agent"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_agent" {
  name = "dcjewelry-cloudwatch-agent"
  role = aws_iam_role.cloudwatch_agent.name
}

resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/dcjewelry/ec2"
  retention_in_days = var.log_retention_days
}

resource "aws_sns_topic" "alerts" {
  name = var.alert_topic_name
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each = var.ec2_instances

  alarm_name          = "dcjewelry-${replace(each.key, "_", "-")}-cpu-high"
  alarm_description   = "${each.key} EC2 CPU exceeds ${var.cpu_threshold_percent}% for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold_percent
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  for_each = var.ec2_instances

  alarm_name          = "dcjewelry-${replace(each.key, "_", "-")}-memory-high"
  alarm_description   = "${each.key} EC2 memory usage exceeds ${var.memory_threshold_percent}% for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "mem_used_percent"
  namespace           = "DCJewelry/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold_percent
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  for_each = var.ec2_instances

  alarm_name          = "dcjewelry-${replace(each.key, "_", "-")}-disk-high"
  alarm_description   = "${each.key} EC2 root disk usage exceeds ${var.disk_threshold_percent}% for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "disk_used_percent"
  namespace           = "DCJewelry/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.disk_threshold_percent
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "dcjewelry-rds-cpu-high"
  alarm_description   = "RDS CPU exceeds ${var.cpu_threshold_percent}% for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold_percent
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.database_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "dcjewelry-rds-free-storage-low"
  alarm_description   = "RDS free storage falls below ${var.rds_free_storage_gib} GiB for 10 minutes."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_free_storage_gib * 1024 * 1024 * 1024
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.database_identifier
  }
}

resource "aws_iam_role" "telegram_lambda" {
  name               = "dcjewelry-telegram-alerts"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "telegram_lambda_logs" {
  role       = aws_iam_role.telegram_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "telegram" {
  count = local.telegram_enabled ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/telegram_alert.py"
  output_path = "${path.module}/telegram_alert.zip"
}

resource "aws_lambda_function" "telegram_alerts" {
  count = local.telegram_enabled ? 1 : 0

  function_name    = "dcjewelry-telegram-alerts"
  role             = aws_iam_role.telegram_lambda.arn
  handler          = "telegram_alert.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.telegram[0].output_path
  source_code_hash = data.archive_file.telegram[0].output_base64sha256
  timeout          = 15

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN = var.telegram_bot_token
      TELEGRAM_CHAT_ID   = var.telegram_chat_id
    }
  }
}

resource "aws_sns_topic_subscription" "telegram_lambda" {
  count = local.telegram_enabled ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.telegram_alerts[0].arn
}

resource "aws_lambda_permission" "allow_sns" {
  count = local.telegram_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telegram_alerts[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}
