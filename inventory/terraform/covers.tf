
/*
 * Specification:
 *   S3 Bucket with Public Read access Policy
 *   Load all of the images in cover_images
 */


/***************************
 S3 SECTION
 ***************************/

locals {
  s3_image_bucket = "cover-images-${data.aws_caller_identity.current.account_id}-${terraform.workspace}"
}

resource "aws_s3_bucket" "cover_images" {
  bucket = local.s3_image_bucket

  tags = {
    Name = "Cover Images ${terraform.workspace}"
  }
}

/* a policy to allow public, read-only access to buckets. This replaces
   the deprecated acl.public */
resource "aws_s3_bucket_policy" "cover_images" {
  bucket = local.s3_image_bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          "arn:aws:s3:::${local.s3_image_bucket}",
          "arn:aws:s3:::${local.s3_image_bucket}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cover_images]
}

resource "aws_s3_bucket_public_access_block" "cover_images" {
  bucket = aws_s3_bucket.cover_images.id

  block_public_acls   = false
  block_public_policy = false
}

/***************************
 LOAD OBJECTS SECTION
 ***************************/


/* upload all of our images into buckets. In production, images would be
   dynamic and not managed through Terraform, but this gives a useful
   example of expansion into multiple objects */
resource "aws_s3_object" "book_image" {
  for_each = fileset("../cover_images/", "*.jpg")

  bucket = aws_s3_bucket.cover_images.id
  key    = each.value
  source = "../cover_images/${each.value}"
  etag   = filemd5("../cover_images/${each.value}")
}

/*****************
 CDN SECTION
 *****************/

locals {
  s3_origin_id = "${local.s3_image_bucket}-origin"
}

resource "aws_cloudfront_distribution" "covers" {
  enabled = true

  aliases = ["covers.${var.domain}"]

  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.cover_images.bucket_domain_name
  }

  default_cache_behavior {
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 3600
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method  = "sni-only"
  }

  price_class = "PriceClass_200"
}

/*********************
 DNS for CDN SECTION
 *********************/

/* now lets get CloudFront to have a DNS friendly name */
resource "aws_route53_record" "covers" {
  zone_id = var.route53_zone_id
  name    = "covers.${var.domain}"
  type    = "CNAME"
  ttl     = 3600 
  records = [aws_cloudfront_distribution.covers.domain_name]
}

output "covers_url" {
  value = join("", ["https://", aws_route53_record.covers.name])
}
