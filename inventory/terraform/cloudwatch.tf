
resource "aws_cloudwatch_log_group" "inventory_auth" {
  name         = "/var/log/auth"
  skip_destroy = true
}

import {
  to = aws_cloudwatch_log_group.inventory_auth
  id = "/var/log/auth"
}

resource "aws_cloudwatch_log_metric_filter" "inventory_failed_auths" {
  name           = "inventory-failed-auths-${terraform.workspace}"
  pattern        = "ssh Invalid user"
  log_group_name = aws_cloudwatch_log_group.inventory_auth.name

  metric_transformation {
    name          = "inventory-failed-auths"
    namespace     = "inventory"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_sns_topic" "sec_alarms" {
  name = "sec-alarms"
}

resource "aws_sns_topic_policy" "sec_alarms" {
  arn = aws_sns_topic.sec_alarms.arn
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.sec_alarms.arn
      }
    ]
  })
}

/*
 * Addtional subscriptions can be added in the SNS console here or
 * in the console.
 */
resource "aws_sns_topic_subscription" "sec_alarms_to_alarms" {
  topic_arn = aws_sns_topic.sec_alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "inventory_failed_auths" {
  alarm_name          = "inventory-failed-auths"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = 300
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.inventory_failed_auths.metric_transformation[0].name
  namespace           = "inventory"
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = [aws_sns_topic.sec_alarms.arn]
  alarm_description   = "More than 5 failed auths over 5 minute period"
  unit                = "Count"
}
