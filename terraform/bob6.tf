resource "aws_iam_user" "bob6" {
  name = "bob6"
}

resource "aws_iam_access_key" "bob6_key" {
  user = "${aws_iam_user.bob6.name}"
}

resource "aws_iam_user_policy" "bob6_policy" {
  name = "bob6_policy"
  user = "${aws_iam_user.bob6.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:List*",
        "iam:Get*",
        "ec2:AllocateAddress",
        "ec2:AttachVolume",
        "ec2:CreateDhcpOptions",
        "ec2:CreateFlowLogs",
        "ec2:CreateImage",
        "ec2:CreateRoute",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:DescribeVpcs",
        "ec2:GetConsoleOutput",
        "ec2:GetConsoleScreenshot",
        "ec2:GetPasswordData",
        "ec2:ModifyInstanceAttribute",
        "ec2:RebootInstances",
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
