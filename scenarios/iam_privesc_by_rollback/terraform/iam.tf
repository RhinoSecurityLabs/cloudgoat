#IAM Users
resource "aws_iam_user" "cg-raynor" {
  name = "raynor-${var.cgid}"
  tags = {
    Name     = "cg-raynor-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_access_key" "cg-raynor" {
  user = "${aws_iam_user.cg-raynor.name}"
}

#IAM User Policies
resource "aws_iam_policy" "cg-raynor-policy" {
  name        = "cg-raynor-policy-${var.cgid}"
  description = "cg-raynor-policy"
  policy      = "${file("../assets/policies/v1.json")}"
}

#IAM Policy Attachments
resource "aws_iam_user_policy_attachment" "cg-raynor-attachment" {
  user       = "${aws_iam_user.cg-raynor.name}"
  policy_arn = "${aws_iam_policy.cg-raynor-policy.arn}"
}
