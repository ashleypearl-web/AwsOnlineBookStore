
variable "region" {
  description = "AWS Region"
  type        = string
}

variable "domain" {
  type    = string
  default = "ajmusgrove.net"
}

variable "alarm_email" {
  type    = string
  default = "ajmusgrove@ajmusgrove.com"
}

variable "route53_zone_id" {
  type    = string
  default = "Z0180874I88FNAEZV6FY"
}

variable "service_port" {
  type    = number
  default = "8080"
}

variable "vpc_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.100.1.0/24"
}

variable "subnet2_cidr" {
  type    = string
  default = "10.100.2.0/24"
}


variable "cidr_any" {
  type    = string
  default = "0.0.0.0/0"
}

variable "inventory_server_private_ip" {
  type    = string
  default = "10.100.1.10"
}

variable "instance_type" {
  type    = string
  default = "t4g.nano"
}

variable "guardduty_name" {
  type    = string
  default = "guardduty"
}
