#IAM Role
resource "aws_iam_role" "cg-ec2-role" {
  name = "cg-ec2-role-${var.cgid}"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
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
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    aws_iam_policy.cg-ec2-rds-policy.arn
  ]

  tags = merge(local.default_tags, {
    Name = "cg-ec2-role-${var.cgid}"
  })
}

#IAM Policy for EC2-RDS
resource "aws_iam_policy" "cg-ec2-rds-policy" {
  name        = "cg-ec2-rds-policy"
  description = "cg-ec2-rds-policy"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "rds:DescribeDBInstances"
          ],
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    }
  )

  tags = merge(local.default_tags, {
    Name = "cg-ec2-rds-policy-${var.cgid}"
  })
}

#IAM Instance Profile
resource "aws_iam_instance_profile" "cg-ec2-instance-profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.cg-ec2-role.name
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
    from_port = 9000
    to_port   = 9000
    protocol  = "tcp"
    security_groups = [
      aws_security_group.cg-lb-http-security-group.id
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [
      aws_security_group.cg-lb-http-security-group.id
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
resource "aws_instance" "cg-ubuntu-ec2" {
  ami                         = data.aws_ami.ubuntu.image_id
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.cg-ec2-instance-profile.name
  subnet_id                   = aws_subnet.cg-public-subnet-1.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.cg-ec2-key-pair.key_name

  vpc_security_group_ids = [
    aws_security_group.cg-ec2-ssh-security-group.id,
    aws_security_group.cg-ec2-http-security-group.id
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  provisioner "file" {
    source      = "../assets/rce_app/app.zip"
    destination = "/home/ubuntu/app.zip"
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
        curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
        DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs postgresql-client unzip
        psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.cg-psql-rds.endpoint}/cloudgoat \
        -c "CREATE TABLE sensitive_information (name VARCHAR(50) NOT NULL, value VARCHAR(50) NOT NULL);"
        psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.cg-psql-rds.endpoint}/cloudgoat \
        -c "INSERT INTO sensitive_information (name,value) VALUES ('Super-secret-passcode',E'V\!C70RY-4hy2809gnbv40h8g4b');"
        sleep 15s
        cd /home/ubuntu
        unzip app.zip -d ./app
        cd app
        node index.js &
        echo -e "\n* * * * * root node /home/ubuntu/app/index.js &\n* * * * * root sleep 10; curl GET http://${aws_lb.cg-lb.dns_name}/mkja1xijqf0abo1h9glg.html &\n* * * * * root sleep 10; node /home/ubuntu/app/index.js &\n* * * * * root sleep 20; node /home/ubuntu/app/index.js &\n* * * * * root sleep 30; node /home/ubuntu/app/index.js &\n* * * * * root sleep 40; node /home/ubuntu/app/index.js &\n* * * * * root sleep 50; node /home/ubuntu/app/index.js &\n" >> /etc/crontab
        EOF

  volume_tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
  })
  tags = merge(local.default_tags, {
    Name = "cg-ubuntu-ec2-${var.cgid}"
  })
}
