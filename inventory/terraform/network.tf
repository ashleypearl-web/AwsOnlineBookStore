
/*
 * Setup network, including VPC, Subnets, Route Tables, and Internet Gateway
 *
 * Specifications:
 *    VPC CIDR: 10.100.0.0/16 (var.vpc_cidr)
 *    Subnet CIDR: 10.100.1.0/24 (var.subnet_cidr)
 *    Subnet AZ: (data.aws_availability_zones.azs.names[0])
 *    Route Table: Default route to IGW
 *    Security Group: Allow ping, 80, 8080, 22
 *    NACL: Ingress: Allow ping (ICMP echo request), 8080, 22 ; Deny 3389
 *      Egress: Allow dynamic app ports, 80 (for apt) and Echo-Reply for ping
 */


/***********************************
 * Pull in AZs for the Region
 ***********************************/
data "aws_availability_zones" "azs" {
  state = "available"
}

output "availability_zone" {
  value = element(data.aws_availability_zones.azs.names, 0)
}

/***********************************
 * VPC 
 ***********************************/

resource "aws_vpc" "inventory" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "inventory-${terraform.workspace}"
  }
}

/***********************************
 * Internet Gateway (IGW) for the VPC
 ***********************************/

resource "aws_internet_gateway" "inventory" {
  vpc_id = aws_vpc.inventory.id

  tags = {
    Name = "inventory-${terraform.workspace}"
  }
}

/***********************************
 * Subnets in first AZ of the region
 ***********************************/

resource "aws_subnet" "inventory" {
  vpc_id            = aws_vpc.inventory.id
  cidr_block        = var.subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]

  map_public_ip_on_launch = true

  tags = {
    Name = "inventory-az1-${terraform.workspace}"
  }
}

/***********************************
 * Route Table, Default to IGW
 ***********************************/

resource "aws_route_table" "inventory" {
  vpc_id = aws_vpc.inventory.id

  /* - This is an inline route table. Will conflict with externa routes
   * for instance to another VPC
   *
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inventory.id
  }
  */

  tags = {
    Name = "inventory-${terraform.workspace}"
  }
}

/* externalized route */
resource "aws_route" "inventory2igw" {
  route_table_id         = aws_route_table.inventory.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inventory.id
}

/* attach the route table to the subnet */
resource "aws_route_table_association" "inventory" {
  subnet_id      = aws_subnet.inventory.id
  route_table_id = aws_route_table.inventory.id
}

/***********************************
 * Network Access Control List (NACL)
 ***********************************/

resource "aws_network_acl" "inventory" {
  vpc_id     = aws_vpc.inventory.id
  subnet_ids = [aws_subnet.inventory.id]

  ingress {
    rule_no    = 10
    from_port  = 0
    to_port    = 0
    icmp_type  = 8
    icmp_code  = -1
    cidr_block = "0.0.0.0/0"
    protocol   = "icmp"
    action     = "allow"
  }

  ingress {
    rule_no    = 100
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  ingress { /* added in for LB */
    rule_no    = 105
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  ingress {
    rule_no    = 110
    from_port  = 8080
    to_port    = 8080
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  ingress {
    rule_no    = 120
    from_port  = 3389
    to_port    = 3389
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "deny"
  }

  ingress {
    rule_no    = 125
    from_port  = 49152
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  /* allow ping reply */
  egress {
    rule_no    = 10
    from_port  = 0
    to_port    = 0
    icmp_type  = 0
    icmp_code  = -1
    cidr_block = "0.0.0.0/0"
    protocol   = "icmp"
    action     = "allow"
  }

  /* dynamic outbound activation ports */
  egress {
    rule_no    = 120
    from_port  = 49152
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  /* to allow apt get */
  egress {
    rule_no    = 130
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  egress {
    rule_no    = 140
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  tags = {
    Name = "inventory-${terraform.workspace}"
  }
}

/***********************************
 * Security Group, used by any instance
 ***********************************/
resource "aws_security_group" "inventory" {
  name        = "inventory-sg"
  description = "Allow SSH, PING, HTTP, and Service Port"
  vpc_id      = aws_vpc.inventory.id

  ingress {
    description = "ping"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "service"
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
