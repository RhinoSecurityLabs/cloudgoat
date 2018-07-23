resource "aws_iam_user" "administrator" {
  name = "administrator"
  force_destroy = "true"
}

resource "aws_iam_user_login_profile" "administrator" {
  user = "${aws_iam_user.administrator.name}"
  pgp_key = "${file("../keys/pgp_cloudgoat")}"
}

resource "aws_iam_user_policy_attachment" "administrator" {
  user       = "${aws_iam_user.administrator.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
