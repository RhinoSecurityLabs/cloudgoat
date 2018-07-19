resource "aws_iam_user" "user3" {
  name = "user3"
}

resource "aws_iam_access_key" "user3_key" {
  user = "${aws_iam_user.user3.name}"
}

resource "aws_iam_user_policy" "user3_policy" {
  name = "user3_policy"
  user = "${aws_iam_user.user3.name}"

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
