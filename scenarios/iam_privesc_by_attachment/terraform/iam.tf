#IAM Users
resource "aws_iam_user" "cg-kerrigan" {
  name = "kerrigan"
  tags = {
    Name = "cg-kerrigan-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_iam_access_key" "cg-kerrigan" {
  user = "${aws_iam_user.cg-kerrigan.name}"
}
#IAM User Policies
resource "aws_iam_policy" "cg-kerrigan-policy" {
  name = "cg-kerrigan-policy"
  description = "cg-kerrigan-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "iam:PassRole",
                "iam:ListInstanceProfiles",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "ec2:AssociateIamInstanceProfile",
                "ec2:DescribeIamInstanceProfileAssociations",
                "ec2:RunInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ec2:CreateKeyPair",
            "Resource": "*"
        },
        {
          "Action": [
            "ec2:DescribeInstances","ec2:DescribeVpcs", "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_user_policy_attachment" "cg-kerrigan-attachment" {
  user = "${aws_iam_user.cg-kerrigan.name}"
  policy_arn = "${aws_iam_policy.cg-kerrigan-policy.arn}"
}
# IAM Role for EC2 Mighty
resource "aws_iam_role" "cg-ec2-mighty-role" {
  name = "cg-ec2-mighty-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = {
      Name = "CloudGoat ${var.cgid} EC2 Mighty Role"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
# IAM Role for EC2 Meek
resource "aws_iam_role" "cg-ec2-meek-role" {
  name = "cg-ec2-meek-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = {
      Name = "CloudGoat ${var.cgid} EC2 Meek Role"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#IAM Policy for EC2 Mighty
resource "aws_iam_policy" "cg-ec2-mighty-policy" {
  name = "cg-ec2-mighty-policy"
  description = "cg-ec2-mighty-policy"
  policy =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
#IAM Policy for EC2 meek
resource "aws_iam_policy" "cg-ec2-meek-policy" {
  name = "cg-ec2-meek-policy"
  description = "cg-ec2-meek-policy"
  policy =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Deny",
      "Resource": "*"
    }
  ]
}
EOF
}
#IAM Role Policy Attachment for EC2 Mighty
resource "aws_iam_role_policy_attachment" "cg-ec2-mighty-role-policy-attachment-ec2" {
  role = "${aws_iam_role.cg-ec2-mighty-role.name}"
  policy_arn = "${aws_iam_policy.cg-ec2-mighty-policy.arn}"
}
#IAM Role Policy Attachment for EC2 Meek
resource "aws_iam_role_policy_attachment" "cg-ec2-meek-role-policy-attachment-ec2" {
  role = "${aws_iam_role.cg-ec2-meek-role.name}"
  policy_arn = "${aws_iam_policy.cg-ec2-meek-policy.arn}"
}
#IAM Instance Profile for Meek EC2 instances
resource "aws_iam_instance_profile" "cg-ec2-meek-instance-profile" {
  name = "cg-ec2-meek-instance-profile-${var.cgid}"
  role="${aws_iam_role.cg-ec2-meek-role.name}"
}