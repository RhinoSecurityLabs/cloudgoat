resource "aws_key_pair" "bob-ec2-key-pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh-public-key-for-ec2)
}

resource "aws_instance" "cg_flag_shop_server" {
  ami                         = "ami-0a313d6098716f372"
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
      user        = "ubuntu"
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

        echo 'export AWS_ACCESS_KEY_ID=${aws_iam_access_key.cg-web-sqs-manager_access_key.id}' >> /etc/environment
        echo 'export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.cg-web-sqs-manager_access_key.secret}' >> /etc/environment
        echo 'export AWS_RDS=${aws_db_instance.cg-rds.endpoint}' >> /etc/environment
        echo 'export AWS_SQS_URL=${aws_sqs_queue.cg_cash_charge.arn}' >> /etc/environment

        sudo apt update
        sudo apt install unzip
        sudo apt install -y python3-pip
        sudo pip3 install Flask
        sudo pip3 install pymysql
        sudo pip3 install boto3
        sudo apt install -y mysql-client

        cd /home/ec2-user
        unzip my_flask_app.zip -d ./my_flask_app
        sudo chmod +x *.py
        cd my_flask_app

        mysql -h ${aws_db_instance.cg-rds.endpoint} -u ${aws_db_instance.cg-rds.username} -p${aws_db_instance.cg-rds.password} ${aws_db_instance.cg-rds.db_name} < /home/ec2-user/insert_data.sql


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


resource "aws_iam_instance_profile" "cg-ec2-instance-profile" {
  name = "cg-${var.scenario-name}-${var.cgid}-ecs-agent"
  role = aws_iam_role.ec2_profile_role.name
}

resource "aws_iam_role" "ec2_profile_role" {
  name = "cg-${var.scenario-name}-ec2-profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
