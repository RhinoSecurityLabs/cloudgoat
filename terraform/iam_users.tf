resource "aws_iam_user" "user1" {
  name = "user1"
}

resource "aws_iam_access_key" "user1_key" {
  user = "${aws_iam_user.user1.name}"
}

resource "aws_iam_user" "user2" {
  name = "user2"
}

resource "aws_iam_access_key" "user2_key" {
  user = "${aws_iam_user.user2.name}"
}

resource "aws_iam_user" "user3" {
  name = "user3"
}

resource "aws_iam_access_key" "user3_key" {
  user = "${aws_iam_user.user3.name}"
}

resource "aws_iam_user" "user4" {
  name = "user4"
}

resource "aws_iam_access_key" "user4_key" {
  user = "${aws_iam_user.user4.name}"
}

resource "aws_iam_user" "user5" {
  name = "user5"
}

resource "aws_iam_access_key" "user5_key" {
  user = "${aws_iam_user.user5.name}"
}
