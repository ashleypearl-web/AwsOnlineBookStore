
/* declare the certificate */
resource "aws_acm_certificate" "main" {
  provider = aws.acm

  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

/* if using a non-AWS domain provider, comment out the section below
   and use the console to retrieve validation information */

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
  allow_overwrite = true

}

/* now connect the DNS records to the certificate for validation for each
   instance of the acm_validation record. In reality there should be only 1 */

resource "aws_acm_certificate_validation" "main" {
  for_each = aws_route53_record.acm_validation

  provider = aws.acm

  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = [aws_route53_record.acm_validation[each.key].fqdn]
}
