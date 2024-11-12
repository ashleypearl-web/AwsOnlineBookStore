
/*
 * Set up Guard Duty. VPC Flow Logs and DNS Logs are automatic
 * for S3, Lambda, and Malware we'll add those features. These
 * aws_guardduty_detector_feature resources take the place of
 * aws_guardduty_detector.data_sources
 */


/****************************
 * Setup Guard Duty Detector
 ****************************/

resource "aws_guardduty_detector" "main" {
  enable = true
}

/****************************
 * Add Detector Features
 ****************************/

resource "aws_guardduty_detector_feature" "s3" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "lambda" {
  detector_id = aws_guardduty_detector.main.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "malware" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

/******************************************
 * ClouddWatch Events for GuardDuty Findings
 ******************************************/

resource "aws_cloudwatch_event_rule" "guardduty" {
  description = "Event Rule to capture GuardDuty findings to publish to SNS"
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty" {
  rule      = aws_cloudwatch_event_rule.guardduty.name
  target_id = "GuardDutyToSNS"
  arn       = aws_sns_topic.guardduty.arn
  input_transformer {
    input_paths = {
      severity            = "$.detail.severity",
      Finding_ID          = "$.detail.id",
      Finding_Type        = "$.detail.type",
      region              = "$.region",
      Finding_description = "$.detail.description"
    }
    input_template = "\"You have a severity <severity> GuardDuty finding type <Finding_Type> in the <region> region.\"\n \"Finding Description:\" \"<Finding_description>. \"\n \"For more details open the GuardDuty console at https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<Finding_ID>\""
  }
}

/******************************************
 * Setup SNS To Publish GuardDuty Findings
 ******************************************/

resource "aws_sns_topic" "guardduty" {
  name = var.guardduty_name
}

resource "aws_sns_topic_subscription" "guardduty_ajmusgrove" {
  topic_arn = aws_sns_topic.guardduty.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

/* allow cloudwatch to publish events */
data "aws_iam_policy_document" "cloudwatch_publish_guardduty_sns" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.guardduty.arn]
  }
}

resource "aws_sns_topic_policy" "cloudwatch_guardduty" {
  arn    = aws_sns_topic.guardduty.arn
  policy = data.aws_iam_policy_document.cloudwatch_publish_guardduty_sns.json
}
