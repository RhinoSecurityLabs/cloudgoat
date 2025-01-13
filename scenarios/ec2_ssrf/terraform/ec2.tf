resource "aws_iam_policy" "ec2_policy" {
  name        = "cg-ec2-role-policy-${var.cgid}"
  description = "Policy for the IAM role used by the EC2 instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name        = "cg-ec2-role-${var.cgid}"
  description = "IAM role used by the CloudGoat EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.ec2_policy.arn
  ]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "ec2_security_group" {
  name        = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "cg-ec2-ssh-${var.cgid}"
  }
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh_public_key)
}

resource "aws_instance" "ubuntu_ec2" {
  ami                         = data.aws_ami.ec2.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]

  key_name = aws_key_pair.ec2_key_pair.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  provisioner "file" {
    source      = data.archive_file.app.output_path
    destination = "/home/ubuntu/app.zip"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }

  user_data = <<-EOF
        #!/bin/bash
        apt-get update
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        DEBIAN_FRONTEND=noninteractive apt-get -y install nodejs unzip
        cd /home/ubuntu
        unzip app.zip -d ./app
        cd app
        npm install
        sudo node app.js &
        echo -e "\n* * * * * root node /home/ubuntu/app/app.js &\n* * * * * root sleep 10; node /home/ubuntu/app/app.js &\n* * * * * root sleep 20; node /home/ubuntu/app/app.js &\n* * * * * root sleep 30; node /home/ubuntu/app/app.js &\n* * * * * root sleep 40; node /home/ubuntu/app/app.js &\n* * * * * root sleep 50; node /home/ubuntu/app/app.js &\n" >> /etc/crontab
  EOF

  volume_tags = {
    Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
  }
  tags = {
    Name = "cg-ubuntu-ec2-${var.cgid}"
  }
}
