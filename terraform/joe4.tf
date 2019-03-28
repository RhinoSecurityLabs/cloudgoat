resource "aws_iam_user" "joe4" {
  name = "joe4"
}

resource "aws_iam_access_key" "joe4_key" {
  user = "${aws_iam_user.joe4.name}"
}

resource "aws_iam_user_policy_attachment" "joe4" {
  user       = "${aws_iam_user.joe4.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
