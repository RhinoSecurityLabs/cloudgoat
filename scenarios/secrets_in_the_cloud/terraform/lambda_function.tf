# This Terraform file creates the following AWS Lambda Resources:
# - An AWS Lambda Resource
# - An AWS IAM Role
# - An AWS IAM Role Policy

resource "aws_lambda_function" "this" {
  function_name = "cloudgoat-secrets-lambda-${var.cgid}"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

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
