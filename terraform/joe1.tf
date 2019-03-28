resource "aws_iam_user" "joe1" {
  name = "joe1"
}

resource "aws_iam_access_key" "joe1_key" {
  user = "${aws_iam_user.joe1.name}"
}

resource "aws_iam_user_policy_attachment" "joe1" {
  user       = "${aws_iam_user.joe1.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
