resource "aws_lambda_function" "this" {
  function_name = "cloudgoat-secrets-lambda-${var.cgid}"

  filename         = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.8"

  role = aws_iam_role.lambda_execution.arn
  handler = "lambda_function.lambda_handler"

  environment {
    variables = {
      API_KEY = "DavidsDelightfulDonuts2023"
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution_role-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy-${var.cgid}"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:Describe*",
          "rds:ListTagsForResource"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = "secretsmanager:GetSecretValue"
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.this.arn
      }
    ]
  })
}
