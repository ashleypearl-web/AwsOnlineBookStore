
/* this is created by AWS external to Terraform and will be imported */
resource "aws_route53_zone" "main" {
  name = var.domain

  lifecycle {
    prevent_destroy = true
  }
}
