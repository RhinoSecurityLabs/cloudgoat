#IAM Users
resource "aws_iam_user" "cg-solus" {
  name = "solus-${var.cgid}"
  tags = {
    Name = "cg-solus-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_iam_access_key" "cg-solus" {
  user = "${aws_iam_user.cg-solus.name}"
}
resource "aws_iam_user" "cg-wrex" {
  name = "wrex-${var.cgid}"
  tags = {
    Name = "cg-wrex-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_iam_access_key" "cg-wrex" {
  user = "${aws_iam_user.cg-wrex.name}"
}
resource "aws_iam_user" "cg-shepard" {
  name = "shepard-${var.cgid}"
  tags = {
    Name = "cg-shepard-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_iam_access_key" "cg-shepard" {
  user = "${aws_iam_user.cg-shepard.name}"
}
#IAM User Policies
resource "aws_iam_policy" "cg-solus-policy" {
  name = "cg-solus-policy-${var.cgid}"
  description = "cg-solus-policy-${var.cgid}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "solus",
            "Effect": "Allow",
            "Action": [
                "lambda:Get*",
                "lambda:List*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "cg-wrex-policy" {
  name = "cg-wrex-policy-${var.cgid}"
  description = "cg-wrex-policy-${var.cgid}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "wrex",
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "cg-shepard-policy" {
  name = "cg-shepard-policy-${var.cgid}"
  description = "cg-shepard-policy-${var.cgid}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "shepard",
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}
#User Policy Attachments
resource "aws_iam_user_policy_attachment" "cg-solus-attachment" {
  user = "${aws_iam_user.cg-solus.name}"
  policy_arn = "${aws_iam_policy.cg-solus-policy.arn}"
}
resource "aws_iam_user_policy_attachment" "cg-wrex-attachment" {
  user = "${aws_iam_user.cg-wrex.name}"
  policy_arn = "${aws_iam_policy.cg-wrex-policy.arn}"
}
resource "aws_iam_user_policy_attachment" "cg-shepard-attachment" {
  user = "${aws_iam_user.cg-shepard.name}"
  policy_arn = "${aws_iam_policy.cg-shepard-policy.arn}"
}