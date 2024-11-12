
/***************************
 S3 SECTION FOR LOGING
 ***************************/

locals {
  s3_alb_logs_bucket = "alb-logs-${data.aws_caller_identity.current.account_id}-${terraform.workspace}"
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = local.s3_alb_logs_bucket

  tags = {
    Name = "Inventory ALB Logs ${terraform.workspace}"
  }
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "alb_logs_access" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }

    actions = ["*"]

    resources = [aws_s3_bucket.alb_logs.arn,
    "${aws_s3_bucket.alb_logs.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "alb_logs_access" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs_access.json
}

resource "aws_security_group" "inventory_alb" {
  name        = "inventory-alb-${terraform.workspace}"
  description = "Security Group for the Inventory App Load Balancer"
  vpc_id      = aws_vpc.inventory.id

  ingress {
    description = "https inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_any]
  }

  ingress {
    description = "http inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_any]
  }

  egress {
    description = "NginX"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }

  egress {
    description = "Inventory Application"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }
}

/***********************************
 * Second Subnet required by ALB
 ***********************************/

resource "aws_subnet" "inventory2" {
  vpc_id            = aws_vpc.inventory.id
  cidr_block        = var.subnet2_cidr
  availability_zone = data.aws_availability_zones.azs.names[1]

  map_public_ip_on_launch = true

  tags = {
    Name = "inventory-az2-${terraform.workspace}"
  }
}

resource "aws_lb" "inventory" {
  name               = "inventoy-tb-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.inventory_alb.id]
  subnets            = [aws_subnet.inventory.id, aws_subnet.inventory2.id]

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-inventory-access-${terraform.workspace}"
    enabled = true
  }

  connection_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-inventory-connection-${terraform.workspace}"
    enabled = true
  }

  tags = {
    Name        = "inventory"
    Environment = "${terraform.workspace}" == "default" ? "production" : "non-production"
  }
}

/* wait until non-inline NACL 
resource "aws_network_acl_rule" "allow_https" {
    network_acl_id = aws_network_acl.inventory.id
    rule_number = 105
    from_port = 443
    to_port = 443
    cidr_block = var.cidr_any
    protocol = "tcp"
    rule_action = "allow"
}
*/


resource "aws_lb_listener" "storefront" {
  load_balancer_arn = aws_lb.inventory.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_lb_listener_rule" "nginx" {
    listener_arn = aws_lb_listener.storefront.arn
    priority = 100

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.nginx.arn
    }

    /* make this the default action */
    condition {
        path_pattern {
            values = [ "/*" ]
        }
    }
}

resource "aws_lb_listener_rule" "inventory" {
    listener_arn = aws_lb_listener.storefront.arn
    priority = 90

    action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "Placeholder for Inventory"
            status_code = 200
        }
    }

    condition {
        path_pattern {
            values = [ "/inventory", "/inventory/*" ]
        }
    }
}

resource "aws_lb_target_group" "nginx" {
  name     = "nginx-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.inventory.id
}

resource "aws_lb_target_group_attachment" "attach_nginx" {
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.inventory_server.id
  port             = 80
}

resource "aws_lb_listener" "storefront_http2https" {
  load_balancer_arn = aws_lb.inventory.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = "www.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.inventory.dns_name]
}

output "alb_cname" {
  value = aws_lb.inventory.dns_name
}
