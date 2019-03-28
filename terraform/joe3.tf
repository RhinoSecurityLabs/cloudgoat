resource "aws_iam_user" "joe3" {
  name = "joe3"
}

resource "aws_iam_access_key" "joe3_key" {
  user = "${aws_iam_user.joe3.name}"
}

resource "aws_iam_user_policy_attachment" "joe3" {
  user       = "${aws_iam_user.joe3.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
