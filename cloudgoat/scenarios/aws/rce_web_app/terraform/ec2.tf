resource "aws_iam_role" "ec2" {
  depends_on = [
    aws_iam_policy.ec2_rds
  ]

  name                  = "cg-ec2-role-${var.cgid}"
  force_detach_policies = true

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
}


resource "aws_iam_role_policy_attachments_exclusive" "ec2" {
  role_name = aws_iam_role.ec2.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    aws_iam_policy.ec2_rds.arn
  ]
}


#IAM Policy for EC2-RDS
resource "aws_iam_policy" "ec2_rds" {
  name        = "cg-ec2-rds-policy"
  description = "cg-ec2-rds-policy"
  policy = jsonencode({
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
  })
}


#IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2.name
}


#Security Groups
resource "aws_security_group" "ec2_ssh" {
  name        = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
  vpc_id      = aws_vpc.this.id

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

  tags = {
    Name = "cg-ec2-ssh-${var.cgid}"
  }
}

resource "aws_security_group" "ec2_http" {
  name        = "cg-ec2-http-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port = 9000
    to_port   = 9000
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb_http.id
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [
      aws_security_group.lb_http.id
    ]
  }

  tags = {
    Name = "cg-ec2-http-${var.cgid}"
  }
}


#AWS Key Pair
resource "aws_key_pair" "this" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh_public_key)
}


#EC2 Instance
resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu.image_id
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.this.key_name

  vpc_security_group_ids = [
    aws_security_group.ec2_ssh.id,
    aws_security_group.ec2_http.id
  ]

  root_block_device {
    volume_type           = "gp2"
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
        curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
        DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs postgresql-client unzip
        psql postgresql://${var.rds_username}:${var.rds_password}@${aws_db_instance.postgres.endpoint}/cloudgoat \
        -c "CREATE TABLE sensitive_information (name VARCHAR(50) NOT NULL, value VARCHAR(50) NOT NULL);"
        psql postgresql://${var.rds_username}:${var.rds_password}@${aws_db_instance.postgres.endpoint}/cloudgoat \
        -c "INSERT INTO sensitive_information (name,value) VALUES ('Super-secret-passcode',E'V\!C70RY-4hy2809gnbv40h8g4b');"
        sleep 15s
        cd /home/ubuntu
        unzip app.zip -d ./app
        cd app
        node index.js &
        echo -e "\n* * * * * root node /home/ubuntu/app/index.js &\n* * * * * root sleep 10; curl GET http://${aws_lb.this.dns_name}/mkja1xijqf0abo1h9glg.html &\n* * * * * root sleep 10; node /home/ubuntu/app/index.js &\n* * * * * root sleep 20; node /home/ubuntu/app/index.js &\n* * * * * root sleep 30; node /home/ubuntu/app/index.js &\n* * * * * root sleep 40; node /home/ubuntu/app/index.js &\n* * * * * root sleep 50; node /home/ubuntu/app/index.js &\n" >> /etc/crontab
        EOF

  volume_tags = {
    Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
  }
  tags = {
    Name = "cg-ubuntu-ec2-${var.cgid}"
  }
}
