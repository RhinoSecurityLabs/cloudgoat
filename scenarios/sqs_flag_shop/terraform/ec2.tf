resource "aws_key_pair" "bob_ec2" {
  key_name   = "cg-ec2-${var.cgid}"
  public_key = file(var.ssh_public_key)
}


resource "aws_instance" "flag_shop_server" {
  ami           = data.aws_ami.ubuntu_image.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.bob_ec2.key_name

  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  provisioner "file" {
    source      = data.archive_file.flask_app.output_path
    destination = "/home/ubuntu/my_flask_app.zip"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "source/initialize_database.sql"
    destination = "/home/ubuntu/initialize_database.sql"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }

  user_data = <<-EOF
        #!/bin/bash

        echo 'export AWS_ACCESS_KEY_ID=${aws_iam_access_key.web_sqs_manager.id}' >> /etc/environment
        echo 'export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.web_sqs_manager.secret}' >> /etc/environment
        echo 'export AWS_RDS=${aws_db_instance.rds.address}' >> /etc/environment
        echo 'export AWS_SQS_URL=${aws_sqs_queue.cash_charge.url}' >> /etc/environment
        echo 'export auth=${var.sqs_auth}' >> /etc/environment

        sudo apt update
        sudo apt install -y mysql-client python3-pip unzip
        sudo pip3 install boto3 Flask pymysql
        cd /home/ubuntu
        mysql -h ${aws_db_instance.rds.address} -u ${var.database_username} -p${var.database_password} cash < /home/ubuntu/initialize_database.sql
        unzip my_flask_app.zip
        chmod -R +x my_flask_app/*.py
        cd my_flask_app
        sudo python3 app.py
        EOF

  volume_tags = {
    Name = "cg-${var.cgid}-ec2"
  }
  tags = {
    Name = "cg-linux-ec2-${var.cgid}"
  }
}
