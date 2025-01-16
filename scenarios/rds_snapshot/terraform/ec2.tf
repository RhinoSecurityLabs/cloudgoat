data "aws_ami" "ubuntu_image" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
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

resource "aws_key_pair" "cg-ec2-key-pair" {
  key_name = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh-public-key-for-ec2)
}

resource "aws_iam_instance_profile" "cg-ec2-instance-profile" {
  name = "cg-david_profile"
  role = aws_iam_role.cg-ec2-admin-role.name
}

resource "aws_instance" "cg-ec2-instance" {
  ami                  = data.aws_ami.ubuntu_image.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.cg-ec2-instance-profile.name
  key_name             = aws_key_pair.cg-ec2-key-pair.key_name
  subnet_id            = aws_subnet.cg-subnet-1.id
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  vpc_security_group_ids = [
    aws_security_group.cg-ec2-ssh-security-group.id,
  ]
  tags        = {
      Name = "cg-david-${var.cgid}"
  }

  depends_on = [aws_db_instance.cg-rds-db_instance]

  provisioner "file" {
    source      = "../assets/insert_data.sql"
    destination = "/home/ubuntu/insert_data.sql"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh-private-key-for-ec2)
      host        = self.public_ip
    }
  }

  // https://developer.hashicorp.com/terraform/language/v1.5.x/resources/provisioners/remote-exec
  provisioner "remote-exec" {
  inline = [
    "sudo apt-get update -y",
    "sudo apt install python3-pip -y",
    "pip3 install --upgrade pip",
    "pip3 install awscli --upgrade --user",
    "sudo apt-get install mysql-client -y",
    "cd /home/ubuntu",
    "mysql -h ${aws_db_instance.cg-rds-db_instance.address} -u ${var.rds-username} -p${var.rds-password} < /home/ubuntu/insert_data.sql",
    "sudo rm /home/ubuntu/insert_data.sql"
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh-private-key-for-ec2)
    host        = self.public_ip
    }
  }
}
