resource "aws_iam_user" "raynor" {
  name = "raynor-${var.cgid}"
}

resource "aws_iam_access_key" "raynor" {
  user = aws_iam_user.raynor.name
}


resource "aws_iam_policy" "versioned_policy" {
  name        = "cg-raynor-policy-${var.cgid}"
  description = "cg-raynor-policy"
  policy      = file("policies/v1.json")
}

resource "aws_iam_user_policy_attachment" "raynor_attachment" {
  user       = aws_iam_user.raynor.name
  policy_arn = aws_iam_policy.versioned_policy.arn
}
