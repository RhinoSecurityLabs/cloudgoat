#IAM Role
resource "aws_iam_role" "cg-banking-WAF-Role" {
  name = "cg-banking-WAF-Role-${var.cgid}"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
          Effect = "Allow"
          Sid    = ""
        }
      ]
    }
  )

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]

  tags = merge(local.default_tags, {
    Name = "cg-banking-WAF-Role-${var.cgid}"
  })
}


#IAM Instance Profile
resource "aws_iam_instance_profile" "cg-ec2-instance-profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.cg-banking-WAF-Role.name
}

#Security Groups
resource "aws_security_group" "cg-ec2-ssh-security-group" {
  name        = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
  vpc_id      = aws_vpc.cg-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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

  tags = merge(local.default_tags, {
    Name = "cg-ec2-ssh-${var.cgid}"
  })
}

resource "aws_security_group" "cg-ec2-http-security-group" {
  name        = "cg-ec2-http-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id      = aws_vpc.cg-vpc.id

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

  tags = merge(local.default_tags, {
    Name = "cg-ec2-http-${var.cgid}"
  })
}

#AWS Key Pair
resource "aws_key_pair" "cg-ec2-key-pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh-public-key-for-ec2)
}

#EC2 Instance
resource "aws_instance" "ec2-vulnerable-proxy-server" {
  ami                         = "ami-0a313d6098716f372"
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.cg-ec2-instance-profile.name
  subnet_id                   = aws_subnet.cg-public-subnet-1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.cg-ec2-ssh-security-group.id,
    aws_security_group.cg-ec2-http-security-group.id
  ]

  key_name = aws_key_pair.cg-ec2-key-pair.key_name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  provisioner "file" {
    source      = "../assets/proxy.com"
    destination = "/home/ubuntu/proxy.com"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh-private-key-for-ec2)
      host        = self.public_ip
    }
  }

  user_data = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y nginx
        ufw allow 'Nginx HTTP'
        cp /home/ubuntu/proxy.com /etc/nginx/sites-enabled/proxy.com
        rm /etc/nginx/sites-enabled/default
        systemctl restart nginx
        EOF

  volume_tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
  })

  tags = merge(local.default_tags, {
    Name = "ec2-vulnerable-proxy-server-${var.cgid}"
  })
}
