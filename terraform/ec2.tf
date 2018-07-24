resource "aws_key_pair" "cloudgoat_key" {
  key_name = "cloudgoat_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPqXeAA1P93EpcoH7aqOAQxgCOfGzPc6yrQwCJiqJTg2IQf5Vaw1HOmAdXUuk9YUuzHIJz7CQzwnUDSB7C8lJfKnV3e0FiyAkm4ipqinEmyr4pbftduBp7BnneP0R0L/+Ffay7K96sxDSSSm55y5dCl6hYcsap795zm+0vz2BhN8YKtXHKSleNnQvXdrRFdUkPk5h8/WEQlIvpjd2DOHCzpmc8M7Lo3I/Ll/GAc9xGlTO8GtN82rbb/Z+dA9RSoUXqcvnpOVZCRUd6Zez/6BnNTBUq6UkVnvvfzapE/ggKGfdnouCa0p6v07y/ZD5DE3aBIGw10Ps66OW8HhxY4MUv joe@joe-ThinkPad-X1-Carbon"
}

resource "aws_instance" "cloudgoat_instance" {
  ami = "${var.ami_id}"
  count = 1
  instance_type = "t2.micro"
  disable_api_termination = false
  security_groups = ["${aws_security_group.cloudgoat_ec2_sg.name}"]
  iam_instance_profile = "${aws_iam_instance_profile.cloudgoat_instance_profile.id}"
  key_name = "cloudgoat_key"

  user_data = "${file("../deploy.py")}"
}

resource "aws_security_group" "cloudgoat_ec2_sg" {
  name = "cloudgoat_ec2_sg"
  description = "SG for EC2 instances"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cloudgoat_ec2_debug_sg" {
  name = "cloudgoat_ec2_debug_sg"
  description = "Debug SG for EC2 instances"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_instance_profile" "cloudgoat_instance_profile" {
  name = "cloudgoat_ec2_iam_profile"
  role = "${aws_iam_role.ec2_role.name}"
}
