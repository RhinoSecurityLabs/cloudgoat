resource "aws_key_pair" "this" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh_public_key)
}

resource "aws_instance" "linux_ec2" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  key_name = aws_key_pair.this.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  provisioner "file" {
    source      = data.archive_file.flask_app.output_path
    destination = "/home/ec2-user/flask_app.zip"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/source/sql_template.tpl", {
      csv_content           = file("source/order_data.csv"), #data.local_file.csv_file.content,
      aws_access_key_id     = aws_iam_access_key.glue_admin_access_key.id,
      aws_secret_access_key = aws_iam_access_key.glue_admin_access_key.secret
    })

    destination = "/home/ec2-user/insert_data.sql"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }

  user_data = <<-EOF
        #!/bin/bash

        echo 'AWS_ACCESS_KEY_ID=${aws_iam_access_key.glue_web_access_key.id}' >> /etc/profile.d/cloudgoat.sh
        echo 'AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.glue_web_access_key.secret}' >> /etc/profile.d/cloudgoat.sh
        echo 'AWS_RDS=${aws_db_instance.rds.endpoint}' >> /etc/profile.d/cloudgoat.sh
        echo 'AWS_S3_BUCKET=${aws_s3_bucket.web.id}' >> /etc/profile.d/cloudgoat.sh
        echo 'AWS_DEFAULT_REGION=${var.region}' >> /etc/profile.d/cloudgoat.sh

        yum update -y
        yum install -y python3 python3-pip
        amazon-linux-extras install -y postgresql14

        psql postgresql://${aws_db_instance.rds.username}:${aws_db_instance.rds.password}@${aws_db_instance.rds.endpoint}/${aws_db_instance.rds.db_name} -f /home/ec2-user/insert_data.sql

        cd /home/ec2-user
        unzip flask_app.zip -d ./flask_app
        cd flask_app

        pip3 install -r requirements.txt

        mv flask.service /etc/systemd/system/flask-app.service

        systemctl daemon-reload
        systemctl enable flask-app.service
        systemctl start flask-app.service
  EOF

  volume_tags = {
    Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
  }

  tags = {
    Name = "cg-linux-ec2-${var.cgid}"
  }
}
