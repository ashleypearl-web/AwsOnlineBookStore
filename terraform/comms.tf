
resource "aws_ses_domain_identity" "main" {
  domain = var.domain

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = aws_ses_domain_identity.main
  id = var.domain
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

import {
  to = aws_ses_domain_dkim.main
  id = var.domain
}

resource "aws_sns_topic" "alarms" {
  name = "books-alarms"
}

resource "aws_sns_topic_subscription" "alarms-admin" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarms_email
}
