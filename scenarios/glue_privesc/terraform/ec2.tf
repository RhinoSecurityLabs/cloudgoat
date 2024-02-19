resource "aws_key_pair" "bob-ec2-key-pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh-public-key-for-ec2)
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}


resource "aws_instance" "cg-linux-ec2" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.cg-ec2-instance-profile.name
  subnet_id                   = aws_subnet.cg-public-subnet-1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.cg-ec2-security-group.id
  ]
  key_name = aws_key_pair.bob-ec2-key-pair.key_name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  provisioner "file" {
    source      = "../assets/my_flask_app.zip"
    destination = "/home/ec2-user/my_flask_app.zip"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh-private-key-for-ec2)
      host        = self.public_ip
    }
  }
  provisioner "file" {
    source      = "../assets/insert_data.sql"
    destination = "/home/ec2-user/insert_data.sql"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh-private-key-for-ec2)
      host        = self.public_ip
    }
  }
  user_data = <<-EOF
        #!/bin/bash

        sudo echo 'export AWS_ACCESS_KEY_ID=${aws_iam_access_key.cg-run-app_access_key.id}' >> /etc/environment
        sudo echo 'export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.cg-run-app_access_key.secret}' >> /etc/environment
        sudo echo 'export AWS_RDS=${aws_db_instance.cg-rds.endpoint}' >> /etc/environment
        sudo echo 'export AWS_S3_BUCKET=${aws_s3_bucket.cg-data-from-web.id}' >> /etc/environment
        sudo echo 'export AWS_DEFAULT_REGION=us-east-1' >> /etc/environment

        sudo yum update -y
        sudo yum install -y python3
        sudo yum install -y python3-pip
        sudo yum install -y postgresql

        psql postgresql://${aws_db_instance.cg-rds.username}:${aws_db_instance.cg-rds.password}@${aws_db_instance.cg-rds.endpoint}/${aws_db_instance.cg-rds.db_name} -f /home/ec2-user/insert_data.sql

        pip3 install Flask 
        pip3 install boto3
        pip3 install psycopg2-binary
        pip3 install matplotlib

        cd /home/ec2-user
        unzip my_flask_app.zip -d ./my_flask_app
        mv ./my_flask_app ./my_flask_app_container
        sudo mv ./my_flask_app_container/my_flask_app .
        cd my_flask_app/my_flask_app
        sudo chmod +x *.py

        sudo python3 app.py
        EOF
  volume_tags = {
    Name     = "CloudGoat ${var.cgid} EC2 Instance Root Device"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
  tags = {
    Name     = "cg-linux-ec2-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

