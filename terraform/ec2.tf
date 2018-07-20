resource "aws_instance" "cloudgoat_instance" {
  ami = "${var.ami_id}"
  count = 1
  instance_type = "t2.micro"
  disable_api_termination = false
  security_groups = ["${aws_security_group.cloudgoat_ec2_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.cloudgoat_instance_profile.id}"
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
    to_port         = 65535
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cloudgoat_ec2_debug_sg" {
  name = "cloudgoat_ec2_debug_sg"
  description = "Debug SG for EC2 instances"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh_in" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Stmt1532039706801",
        "Action": [
          "ec2:ModifyVolume",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "iam:UpdateUser",
          "sts:AssumeRole"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "cloudgoat_instance_profile" {
  name = "cloudgoat_ec2_iam_profile"
  role = "${aws_iam_role.ec2_role.name}"
}
