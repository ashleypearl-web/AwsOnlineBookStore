
terraform {
  required_providers {
    aws = {
      version = "~> 5.69.0"
    }
  }
  required_version = "~> 1.9.7"
}

provider "aws" {
  profile = "default"
  region  = var.region
}

/* AWS Certificate Manager requires all certificates in US East 1 */
provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

/*
 * caller identity for AWS available
 */
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

output "aws_account_id" { value = data.aws_caller_identity.current.account_id }
output "aws_account_arn" { value = data.aws_caller_identity.current.arn }
output "aws_user_id" { value = data.aws_caller_identity.current.user_id }

