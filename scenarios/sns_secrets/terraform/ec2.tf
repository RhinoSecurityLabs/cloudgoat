data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "cg-sns-instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.cg-ec2-sns-instance-profile.name
  subnet_id              = aws_subnet.cg_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags = {
    Name     = "cg-sns-instance-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }

  user_data = <<EOF
#!/bin/bash
# Install AWS CLI
yum install -y aws-cli

# Enable password authentication
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart sshd

# Set the root password
echo "root:Rh!n0Cl0udgo@tscenariom@st3rkey" | chpasswd

# Create a cron job to publish to SNS every 5 minutes
echo "* * * * * root aws sns publish --topic-arn ${aws_sns_topic.public_topic.arn} --message 'DEBUG: API GATEWAY KEY ${aws_api_gateway_api_key.cg_api_key.value}' --region ${var.region}" > /etc/cron.d/publish-secret
EOF
}

resource "aws_security_group" "sg" {
  name        = "cg-sns-sg-${var.cgid}"
  description = "Allow SSH and HTTP(s) inbound traffic"
  vpc_id      = aws_vpc.cg_vpc.id

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

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
