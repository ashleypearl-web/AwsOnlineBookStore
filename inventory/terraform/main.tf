
/*
 * Before running your Terraform, run keypairgen.sh in this directory
 * to generate your key pair
 *
 * Specification:
 *  EC2 Instance bringing together everything we've defined
 */

/***************************
 Key Pair for Access
 ***************************/

resource "aws_key_pair" "inventory" {
  key_name   = "inventoryServerKey-${terraform.workspace}"
  public_key = file("../etc/ec2user.pub")
}

resource "aws_instance" "inventory_server" {
  instance_type          = var.instance_type
  ami                    = data.aws_ami.ubuntu_2404.id
  vpc_security_group_ids = [aws_security_group.inventory.id]
  iam_instance_profile   = aws_iam_instance_profile.inventory_server.id
  key_name               = aws_key_pair.inventory.key_name
  subnet_id              = aws_subnet.inventory.id
  private_ip             = var.inventory_server_private_ip

  tags = {
    Name      = "inventory-${terraform.workspace}"
    Inspector = "yes"
  }
}

output "inventory_public_ip" {
  value = aws_instance.inventory_server.public_ip
}

output "inventory_url" {
  value = join("", ["http://", aws_instance.inventory_server.public_ip,
  ":", var.service_port])
}

