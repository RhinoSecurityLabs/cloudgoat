

resource "aws_instance" "easy_path" {
  ami                         = data.aws_ami.amz_linux.image_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_easy_path.name
  // Do I even need the below key since I'm using ssm?
  // key_name = "delete-this-key-now" 
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main2.id]
  user_data              = <<EOF
  #!/bin/bash
  cd /tmp
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl start amazon-ssm-agent
  sudo yum remove awscli.noarch -y
  EOF
  tags = {
    Name    = "easy_path-cg-detection-evasion",
    tag-key = var.cgid
  }
}

resource "aws_instance" "hard_path" {
  ami           = data.aws_ami.amz_linux.image_id
  instance_type = "t2.micro"
  // private_ip = "${var.target_IP}"
  // associate_public_ip_address = true
  subnet_id            = aws_subnet.main.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile_hard_path.name
  // Do I even need the below key since I'm using ssm?
  // key_name = "delete-this-key-now" 
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data              = <<EOF
  #!/bin/bash
  cd /tmp
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl start amazon-ssm-agent
  EOF
  tags = {
    Name    = "hard_path-cg-detection-evasion",
    tag-key = var.cgid
  }
}

resource "aws_security_group" "main" {
  name        = var.cgid
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_security_group" "main2" {
  name        = "${var.cgid}2"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    tag-key = var.cgid
  }
}
