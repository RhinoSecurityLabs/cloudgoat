resource "aws_iam_user" "joe6" {
  name = "joe6"
}

resource "aws_iam_access_key" "joe6_key" {
  user = "${aws_iam_user.joe6.name}"
}

resource "aws_iam_user_policy_attachment" "joe6" {
  user       = "${aws_iam_user.joe6.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
