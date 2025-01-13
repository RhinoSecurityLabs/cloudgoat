#IAM User
resource "aws_iam_user" "chris" {
  name          = "chris-${var.cgid}"
  force_destroy = true

  tags = {
    Name = "cg-chris-${var.cgid}"
  }
}

resource "aws_iam_access_key" "chris" {
  user = aws_iam_user.chris.name
}

resource "aws_iam_policy" "chris_policy" {
  name        = "cg-chris-policy-${var.cgid}"
  description = "cg-chris-policy-${var.cgid}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "chris"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "iam:List*",
          "iam:Get*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "cg-chris-policy-${var.cgid}"
  }
}

resource "aws_iam_user_policy_attachment" "chris_attachment" {
  user       = aws_iam_user.chris.name
  policy_arn = aws_iam_policy.chris_policy.arn
}

# Lambda Assume Roles
resource "aws_iam_role" "lambdaManager_role" {
  name        = "cg-lambdaManager-role-${var.cgid}"
  description = "CloudGoat Lambda manager role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_user.chris.arn
        }
        Effect = "Allow"
      }
    ]
  })

  tags = {
    Name = "cg-debug-role-${var.cgid}"
  }
}

resource "aws_iam_policy" "lambdaManager_policy" {
  name        = "cg-lambdaManager-policy-${var.cgid}"
  description = "cg-lambdaManager-policy-${var.cgid}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "lambdaManager"
        Effect = "Allow"
        Action = [
          "lambda:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "cg-lambdaManager-policy-${var.cgid}"
  }
}

resource "aws_iam_role_policy_attachment" "lambdaManager_role_attachment" {
  role       = aws_iam_role.lambdaManager_role.name
  policy_arn = aws_iam_policy.lambdaManager_policy.arn
}

resource "aws_iam_role" "debug_role" {
  name        = "cg-debug-role-${var.cgid}"
  description = "CloudGoat debug role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  tags = {
    Name = "cg-debug-role-${var.cgid}"
  }
}

resource "aws_iam_role_policy_attachment" "debug_administrator_attachment" {
  role       = aws_iam_role.debug_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
