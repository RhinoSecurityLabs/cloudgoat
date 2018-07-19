resource "aws_instance" "instance" {
  ami = "ami-a9d09ed1"
  count = 1
  instance_type = "t2.small"
  disable_api_termination = false
  security_groups = ["${aws_security_group.ec2_sg.id}"]
}

resource "aws_security_group" "ec2_sg" {
  name = "ec2_sg"
  description = "SG for EC2 instances"
}

resource "aws_security_group_rule" "tcp_out" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2_sg.id}"
}

resource "aws_security_group_rule" "udp_out" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "udp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2_sg.id}"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_iam_profile"
  role = "${aws_iam_role.ec2_role.name}"
}
