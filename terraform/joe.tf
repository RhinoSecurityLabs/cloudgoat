resource "aws_iam_user" "joe" {
  name = "joe"
}

resource "aws_iam_access_key" "joe_key" {
  user = "${aws_iam_user.joe.name}"
}

resource "aws_iam_user_policy" "joe_policy" {
  name = "joe_policy"
  user = "${aws_iam_user.joe.name}"

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
