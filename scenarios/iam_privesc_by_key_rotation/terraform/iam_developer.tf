# Developer IAM User
# The user it not needed for scenario completion
resource "aws_iam_user" "developer" {
  name          = "developer_${var.cgid}"
  force_destroy = true

  tags = {
    developer = "true"
  }
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

resource "aws_iam_user_policy" "developer_manage_view_secrets" {
  name = "DeveloperViewSecrets"
  user = aws_iam_user.developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ViewSecrets"
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      }
    ]
  })
}
