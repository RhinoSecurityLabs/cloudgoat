# #AWS Key Pair
# resource "aws_key_pair" "cg-ec2-key-pair" {
#   key_name = "cg-ec2-key-pair-${var.cgid}"
#   public_key = "${file(var.ssh-public-key-for-ec2)}"
# }

#임시키- 나중에 삭제
resource "aws_key_pair" "bob-ec2-key-pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file("~/.ssh/id_rsa.pub")
}

#cg-ec2-instance-profile 추가 필요
resource "aws_instance" "cg-ubuntu-ec2" {
  ami                         = "ami-05c13eab67c5d8861"
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.cg-ec2-instance-profile.name
  subnet_id                   = aws_subnet.cg-public-subnet-1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.cg-rds-glue-security-group.id,
    aws_security_group.cg-ec2-rds-security-group.id
  ]
  # key_name = "${aws_key_pair.cg-ec2-key-pair.key_name}"
  key_name = aws_key_pair.bob-ec2-key-pair.key_name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  #플라스크 프로비저닝
  provisioner "file" {
    source      = "../assets/my_flask_app.zip"
    destination = "/home/ec2-user/my_flask_app.zip"
    connection {
      type = "ssh"
      user = "ec2-user"
      # private_key = "${file(var.ssh-private-key-for-ec2)}"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  #테스트용 수정 필요
  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y python3
        sudo yum install python3-pip
        pip install Flask 
        pip install boto3
        pip install psycopg2-binary
        pip install matplotlib
        mkdir my_flask_app
        cd my_flask_app
        mkdir templates
        mkdir static

        cd /home/ec2-user
        unzip my_flask_app.zip -d ./my_flask_app
        cd my_flask_app

        nohup python3 my_flask_app/app.py > my_flask_app/flask.log 2>&1 &
        EOF
  volume_tags = {
    Name     = "CloudGoat ${var.cgid} EC2 Instance Root Device"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
  tags = {
    Name     = "cg-linux-ec2-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

