variable "domain_name" {
  description = "The domain name for SES and other resources"
  type        = string
}

variable "alarms_email" {
  description = "The email address for SNS alarms"
  type        = string
}

variable "domain" {
  description = "The domain for Route 53"
  type        = string
}
