resource "aws_iam_user" "joe5" {
  name = "joe5"
}

resource "aws_iam_access_key" "joe5_key" {
  user = "${aws_iam_user.joe5.name}"
}

resource "aws_iam_user_policy_attachment" "joe5" {
  user       = "${aws_iam_user.joe5.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
