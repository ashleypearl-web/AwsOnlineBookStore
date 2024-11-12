
/*
 * Enable CloudTrail Monitoring. This can be used for many purposes,
 * our immediate purpose if Guard Duty
 */

/*******************
 * S3 Section
 *******************/

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "cloudtrail-${local.aws_account_id}-${terraform.workspace}"
  force_destroy = true

  tags = {
    Name = "cloudtrail-${terraform.workspace}"
  }
}

/***************************
 * CloudTrail Bucket Policy
 ***************************/

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid    = "CloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid    = "CloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/cloudtrail/AWSLogs/${local.aws_account_id}/*"]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}

/************************
 * CloudTrail Section
 ************************/

locals {
  cloudtrail_name = "cloudtrail-${terraform.workspace}"
}

resource "aws_cloudtrail" "main" {
  name           = local.cloudtrail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  s3_key_prefix  = "cloudtrail"

  enable_log_file_validation    = false
  include_global_service_events = true
  is_multi_region_trail         = false

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }

    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = ["arn:aws:dynamodb"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }
}
