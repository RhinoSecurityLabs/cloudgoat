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

  user_data = "#cloud-boothook\n#!/bin/bash\nyum update -y\nyum install php -y\nyum install httpd -y\nmkdir -p /var/www/html\ncd /var/www/html\nrm -rf ./*\nprintf \"<?php\\nif(isset(\\$_POST['url'])) {\\n  if(strcmp(\\$_POST['password'], '${var.ec2_web_app_password}') != 0) {\\n    echo 'Wrong password. You just need to find it!';\\n    die;\\n  }\\n  echo '<pre>';\\n  echo(file_get_contents(\\$_POST['url']));\\n  echo '</pre>';\\n  die;\\n}\\n?>\\n<html><head><title>URL Fetcher</title></head><body><form method='POST'><label for='url'>Enter the password and a URL that you want to make a request to (ex: https://google.com/)</label><br /><input type='text' name='password' placeholder='Password' /><input type='text' name='url' placeholder='URL' /><br /><input type='submit' value='Retrieve Contents' /></form></body></html>\" > index.php\n/usr/sbin/apachectl start"
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
  cidr_blocks = ["${file("../tmp/allow_cidr.txt")}"]
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

resource "aws_security_group" "cloudgoat_ec2_debug_sg" {
  name = "cloudgoat_ec2_debug_sg"
  description = "Debug SG for EC2 instances"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${file("../tmp/allow_cidr.txt")}"]
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

resource "aws_iam_policy" "ec2_ip_policy" {
  name = "ec2_ip_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:CreatePolicyVersion"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_ip_attachment" {
  role       = "${aws_iam_role.ec2_role.name}"
  policy_arn = "${aws_iam_policy.ec2_ip_policy.arn}"
}

resource "aws_iam_instance_profile" "cloudgoat_instance_profile" {
  name = "cloudgoat_ec2_iam_profile"
  role = "${aws_iam_role.ec2_role.name}"
}
