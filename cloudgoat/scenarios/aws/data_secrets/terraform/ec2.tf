data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = aws_subnet.subnet.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  # VULNERABILITY: Sensitive credentials stored in User Data
  user_data = <<-EOF
    #!/bin/bash
    echo "ec2-user:CloudGoatInstancePassword!" | chpasswd
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    service sshd restart
  EOF

  tags = {
    Name = "cg-sensitive-ec2-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_security_group" "sg" {
  name        = "cg-sg-${var.cgid}"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-sg-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}