resource "aws_iam_user" "cg-calrissian" {
  name = "calrissian"
  tags = {
    Name = "cg-calrissian-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_iam_access_key" "cg-calrissian" {
  user = "${aws_iam_user.cg-calrissian.name}"
}
resource "aws_iam_user" "cg-solo" {
  name = "solo"
  tags = {
    Name = "cg-solo-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_iam_access_key" "cg-solo" {
  user = "${aws_iam_user.cg-solo.name}"
}
#IAM User Policies
resource "aws_iam_policy" "cg-calrissian-policy" {
  name = "cg-calrissian-policy-${var.cgid}"
  description = "cg-calrissian-policy-${var.cgid}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "calrissian",
            "Effect": "Allow",
            "Action": [
                "rds:CreateDBSnapshot",
                "rds:DescribeDBInstances",
                "rds:ModifyDBInstance",
                "rds:RestoreDBInstanceFromDBSnapshot",
                "rds:DescribeDBSubnetGroups",
                "rds:CreateDBSecurityGroup",
                "rds:DeleteDBSecurityGroup",
                "rds:DescribeDBSecurityGroups",
                "rds:AuthorizeDBSecurityGroupIngress",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "cg-solo-policy" {
  name = "cg-solo-policy-${var.cgid}"
  description = "cg-solo-policy-${var.cgid}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "solo",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "ssm:DescribeParameters",
                "ssm:GetParameter",
                "codebuild:ListProjects",
                "codebuild:BatchGetProjects",
                "codebuild:ListBuilds",
                "ec2:DescribeInstances",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
#User Policy Attachments
resource "aws_iam_user_policy_attachment" "cg-calrissian-attachment" {
  user = "${aws_iam_user.cg-calrissian.name}"
  policy_arn = "${aws_iam_policy.cg-calrissian-policy.arn}"
}
resource "aws_iam_user_policy_attachment" "cg-solo-attachment" {
  user = "${aws_iam_user.cg-solo.name}"
  policy_arn = "${aws_iam_policy.cg-solo-policy.arn}"
}