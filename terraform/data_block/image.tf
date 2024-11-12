
data "aws_ami" "ubuntu_2404" {
    most_recent = true
    
    filter {
        name = "name"
        values = ["*ubuntu-noble-24.04-arm64-server-20240927"]
    }

    filter {
      name = "architecture"
      values = ["arm64"]
    }

    filter {
      name = "root-device-type"
      values = ["ebs"]
    }

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

output "instance_ami_id" {
    value = data.aws_ami.ubuntu_2404.id
}

output "instance_ami_name" {
    value = data.aws_ami.ubuntu_2404.name
}
