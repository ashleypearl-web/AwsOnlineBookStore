
/*
 * Search for an image rather that hardcoding an AMI. AMI IDs are
 * specific to the region, this makes Terraform work multi-region.
 * Note: if we were using Amazon Linux, there is an SSM Parameter
 * that contains an AMI ID for that. But I prefer Ubuntu
 */

data "aws_ami" "ubuntu_2404" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-*-server-20240927"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "instance_ami_id" {
  value = data.aws_ami.ubuntu_2404.id
}

output "instance_ami_name" {
  value = data.aws_ami.ubuntu_2404.name
}
