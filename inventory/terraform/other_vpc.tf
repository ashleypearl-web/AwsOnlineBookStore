

/*
 * This is an example of using VPC Peering within a single account. If
 * there is multiple accounts, there is concept of accepter and requester
 * peers. If there are overlapping IP adress ranges, a better solution
 * may be endpoints
 */

variable "other_vpc_cidr" {
  type    = string
  default = "10.101.0.0/16"
}

variable "other_subnet_cidr" {
  type    = string
  default = "10.101.10.0/24"
}

resource "aws_vpc" "other" {
  cidr_block = var.other_vpc_cidr

  tags = {
    Name = "other_vpc-${terraform.workspace}"
  }
}

/* internal only subnet, not public IP or IGW */
resource "aws_subnet" "other" {
  vpc_id            = aws_vpc.other.id
  cidr_block        = var.other_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[1]

  tags = {
    Name = "other-az2-${terraform.workspace}"
  }
}

resource "aws_route_table" "other" {
  vpc_id = aws_vpc.other.id

  tags = {
    Name = "other-${terraform.workspace}"
  }
}
/* setup to peering connection */
resource "aws_vpc_peering_connection" "other2inventory" {
  vpc_id      = aws_vpc.other.id
  peer_vpc_id = aws_vpc.inventory.id
  auto_accept = true

  tags = {
    Name = "inventory2other"
  }
}

/* main subnet to other */
resource "aws_route" "inventory2other" {
  route_table_id            = aws_route_table.inventory.id
  destination_cidr_block    = var.other_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.other2inventory.id
}

/* return route other to main */
resource "aws_route" "other2inventory" {
  route_table_id            = aws_route_table.other.id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.other2inventory.id
}

