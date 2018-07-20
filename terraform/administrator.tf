resource "aws_iam_user" "administrator" {
  name = "administrator"
}

resource "aws_iam_user_policy_attachment" "administrator" {
    user       = "${aws_iam_user.administrator.name}"
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
