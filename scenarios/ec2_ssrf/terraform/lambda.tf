resource "aws_iam_role" "lambda" {
  name        = "cg-lambda-role-${var.cgid}-service-role"
  description = "Lambda function IAM role"

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
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "cg-lambda-${var.cgid}"
  description   = "Invoke this Lambda function for the win!"
  runtime       = "python3.11"

  role = aws_iam_role.lambda.arn

  handler          = "lambda.handler"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  environment {
    variables = {
      EC2_ACCESS_KEY_ID = aws_iam_access_key.wrex.id
      EC2_SECRET_KEY_ID = aws_iam_access_key.wrex.secret
    }
  }
}
