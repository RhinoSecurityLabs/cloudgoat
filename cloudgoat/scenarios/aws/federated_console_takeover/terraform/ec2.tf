# EC2 Configuration for federated_console_takeover scenario

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group
resource "aws_security_group" "instance_sg" {
  name        = "cg-instance-sg-${var.cgid}"
  description = "SG for the EC2 instance"
  vpc_id      = aws_vpc.vpc.id

  # No inbound rules needed for SSM access
  # SSM uses outbound HTTPS connections

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-instance-sg-${var.cgid}"
  }
}

# EC2 instance with IMDSv2 enabled
resource "aws_instance" "vulnerable_ec2" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_admin_profile.name
  subnet_id            = aws_subnet.subnet.id
  
  # Associate public IP
  associate_public_ip_address = true
  
  # Enable IMDSv2 accessible
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforce IMDSv2
  }
  
  vpc_security_group_ids = [
    aws_security_group.instance_sg.id
  ]
  
  # User data to install tools
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y jq curl wget python3 python3-pip
    pip3 install --upgrade awscli
    echo "export PATH=$PATH:/usr/local/bin" >> /etc/profile
    echo "PS1='\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/bashrc

    echo "==== Installing Session Manager Plugin ===="
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
    dnf install -y ./session-manager-plugin.rpm
    # Make sure the plugin is in the path for all users
    echo "export PATH=\$PATH:/usr/local/bin:/usr/bin" >> /etc/profile
    # Verify plugin installation
    session-manager-plugin --version
    
    # Enable SSM agent
    dnf install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install nano
    dnf install -y nano

  EOF
  
  tags = {
    Name = "cg-vulnerable-ec2-${var.cgid}"
  }
} 