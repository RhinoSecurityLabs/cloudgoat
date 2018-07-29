resource "aws_iam_user" "bob" {
  name = "bob"
}

resource "aws_iam_access_key" "bob_key" {
  user = "${aws_iam_user.bob.name}"
}

resource "aws_iam_user_policy" "bob_policy" {
  name = "bob_policy"
  user = "${aws_iam_user.bob.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:AddUserToGroup",
        "ec2:*",
        "iam:UpdateAssumeRolePolicyDocument"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
