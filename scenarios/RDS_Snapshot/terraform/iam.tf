resource "aws_iam_user" "cg-rds_instance" {
  name = "cg-rds-instance-user-${var.cgid}"
  tags = {
    Name     = "cg-rds-instance-user-${var.cgid}"
  }
}

resource "aws_iam_access_key" "cg-rds_instance" {
  user = aws_iam_user.cg-rds_instance.name
}

resource "aws_iam_user_policy" "cg-rds_instance" {
  name = "cg-rds_instance"
  user = aws_iam_user.cg-rds_instance.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBSnapshots",
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:ModifyDBInstance",
        "iam:ListInstanceProfiles",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "cg-rds_admin" {
  name = "cg-rds_admin"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cg-rds_admin" {
  name = "cg-rds_admin"
  role = aws_iam_role.cg-rds_admin.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
                "s3:*",
                "iam:ListInstanceProfiles",
                "iam:ListRolePolicies",
                "iam:GetRolePolicy"
            ],
      "Resource": "*"
    }
  ]
}
EOF
}
