resource "aws_iam_user" "user4" {
  name = "user4"
}

resource "aws_iam_access_key" "user4_key" {
  user = "${aws_iam_user.user4.name}"
}

resource "aws_iam_user_policy" "user4_policy" {
  name = "user4_policy"
  user = "${aws_iam_user.user4.name}"

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
