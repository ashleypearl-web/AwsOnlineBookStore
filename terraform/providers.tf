
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

/* AWS Certificate Manager requires all certificates in US East 1. That
   is our only use of this alternate provider */
provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

