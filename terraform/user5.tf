resource "aws_iam_user" "user5" {
  name = "user5"
}

resource "aws_iam_access_key" "user5_key" {
  user = "${aws_iam_user.user5.name}"
}

resource "aws_iam_user_policy" "user5_policy" {
  name = "user5_policy"
  user = "${aws_iam_user.user5.name}"

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
