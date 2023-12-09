data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_key_pair" "cg-ec2-key-pair" {
  key_name = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh-public-key-for-ec2)
}

resource "aws_iam_instance_profile" "cg-rds_instance_profile" {
  name = "cg-rds_instance_profile"
  role = aws_iam_role.cg-rds_admin.name
}

resource "aws_instance" "cg-rds_instance" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.cg-rds_instance_profile.name
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
  provisioner "file" {
    source      = "../assets/insert_data.sql"
    destination = "/home/ubuntu/insert_data.sql"
    user_data   = <<-EOF
        #!/bin/bash
        sudo apt update
        sudo apt install -y mysql-client
        cd /home/ubuntu
        mysql -h ${aws_db_instance.cg-rds-db_instance.address} -u ${var.rds-username} -p${var.rds-password} cash < /home/ubuntu/insert_data.sql
        EOF
    tags        = {
      Name = "cg-rds_instance-${var.cgid}"
    }
  }
}