resource "aws_iam_user" "joe2" {
  name = "joe2"
}

resource "aws_iam_access_key" "joe2_key" {
  user = "${aws_iam_user.joe2.name}"
}

resource "aws_iam_user_policy_attachment" "joe2" {
  user       = "${aws_iam_user.joe2.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
