
resource "aws_instance" "main" {
  ami           = var.ami
  instance_type = var.sku

  tags = {
    Name = "my-instance"
  }
}

