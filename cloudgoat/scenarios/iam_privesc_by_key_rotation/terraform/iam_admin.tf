resource "aws_iam_user" "admin" {
  name          = "admin_${var.cgid}"
  force_destroy = true
}

resource "aws_iam_access_key" "admin_one" {
  user   = aws_iam_user.admin.name
  status = "Inactive"
}

resource "aws_iam_access_key" "admin_two" {
  user   = aws_iam_user.admin.name
  status = "Inactive"
}

resource "aws_iam_user_policy_attachment" "admin_iam_read" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_user_policy" "admin_assume_role" {
  name = "AssumeRoles"
  user = aws_iam_user.admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.secretsmanager_role.arn
      }
    ]
  })
}


resource "aws_iam_role" "secretsmanager_role" {
  name                  = "cg_secretsmanager_${var.cgid}"
  description           = "Access to view secrets"
  force_detach_policies = true

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = true
          }
        }
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.role_read_secrets.arn
  ]
}

resource "aws_iam_policy" "role_read_secrets" {
  name        = "cg_view_secrets_${var.cgid}"
  description = "View and retreive secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:ListSecrets"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.primary_secret.arn
      }
    ]
  })
}
