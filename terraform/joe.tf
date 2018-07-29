resource "aws_iam_user" "joe" {
  name = "joe"
}

resource "aws_iam_access_key" "joe_key" {
  user = "${aws_iam_user.joe.name}"
}

resource "aws_iam_user_policy_attachment" "administrator" {
  user       = "${aws_iam_user.joe.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}
