resource "aws_iam_user" "user1" {
  name = "user1"
}

resource "aws_iam_access_key" "user1_key" {
  user = "${aws_iam_user.user1.name}"
}

resource "aws_iam_user_policy" "user1_policy" {
  name = "user1_policy"
  user = "${aws_iam_user.user1.name}"

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
