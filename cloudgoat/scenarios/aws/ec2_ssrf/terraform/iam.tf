resource "aws_iam_user" "solus" {
  name = "solus-${var.cgid}"
}

resource "aws_iam_access_key" "solus" {
  user = aws_iam_user.solus.name
}

resource "aws_iam_policy" "solus" {
  name        = "cg-solus-policy-${var.cgid}"
  description = "IAM policy for the solus user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "solus"
        Effect = "Allow"
        Action = [
          "lambda:Get*",
          "lambda:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "solus" {
  user       = aws_iam_user.solus.name
  policy_arn = aws_iam_policy.solus.arn
}


resource "aws_iam_user" "wrex" {
  name = "wrex-${var.cgid}"
}

resource "aws_iam_access_key" "wrex" {
  user = aws_iam_user.wrex.name
}

resource "aws_iam_policy" "wrex" {
  name        = "cg-wrex-policy-${var.cgid}"
  description = "IAM policy for the wrex user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "wrex"
        Effect   = "Allow"
        Action   = "ec2:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "wrex" {
  user       = aws_iam_user.wrex.name
  policy_arn = aws_iam_policy.wrex.arn
}


resource "aws_iam_user" "shepard" {
  name = "shepard-${var.cgid}"
}

resource "aws_iam_access_key" "shepard" {
  user = aws_iam_user.shepard.name
}

resource "aws_iam_policy" "shepard" {
  name        = "cg-shepard-policy-${var.cgid}"
  description = "IAM policy for the shepard user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "shepard"
        Effect = "Allow"
        Action = [
          "lambda:Get*",
          "lambda:Invoke*",
          "lambda:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "shepard" {
  user       = aws_iam_user.shepard.name
  policy_arn = aws_iam_policy.shepard.arn
}
