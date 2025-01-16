resource "aws_iam_user" "cg-david" {
  name = "cg-rds-instance-user-${var.cgid}"
  tags = {
    Name     = "cg-rds-instance-user-${var.cgid}"
  }
}

resource "aws_iam_access_key" "cg-david" {
  user = aws_iam_user.cg-david.name
}

resource "aws_iam_user_policy" "cg-david-policy" {
  name = "cg-david-policy"
  user = aws_iam_user.cg-david.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:AddTagsToResource",
        "rds:DescribeDBSnapshots",
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:ModifyDBInstance",
        "iam:Get*",
        "iam:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "cg-ec2-admin-role" {
  name = "cg-ec2-admin-role"

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

resource "aws_iam_role_policy" "cg-ec2-admin-policy" {
  name = "cg-ec2-admin-policy"
  role = aws_iam_role.cg-ec2-admin-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
                "s3:*",
                "iam:List*",
                "iam:Get*"
            ],
      "Resource": "*"
    }
  ]
}
EOF
}
