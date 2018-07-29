resource "aws_key_pair" "cloudgoat_key" {
  key_name = "cloudgoat_key"
  public_key = "${var.ec2_public_key}"
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
}

resource "aws_security_group_rule" "ssh_in" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
}

resource "aws_security_group_rule" "allow_all_out" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
}

resource "aws_security_group_rule" "allow_cidr_argument" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["${file("../allow_cidr.txt")}"]
  security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
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
