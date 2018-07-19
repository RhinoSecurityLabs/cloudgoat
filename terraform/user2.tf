resource "aws_iam_user" "user2" {
  name = "user2"
}

resource "aws_iam_access_key" "user2_key" {
  user = "${aws_iam_user.user2.name}"
}

resource "aws_iam_user_policy" "user2_policy" {
  name = "user2_policy"
  user = "${aws_iam_user.user2.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
