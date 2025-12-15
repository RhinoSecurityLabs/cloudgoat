# Create a dummy zip file for the lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  
  source {
    content  = "def lambda_handler(event, context): return 'Hello from CloudGoat'"
    filename = "lambda_function.py"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "cg-lambda-exec-role-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "sensitive_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "cg-lambda-function-${var.cgid}"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  # VULNERABILITY: Credentials stored in Environment Variables
  environment {
    variables = {
      DB_USER_ACCESS_KEY = aws_iam_access_key.lambda_user.id
      DB_USER_SECRET_KEY = aws_iam_access_key.lambda_user.secret
    }
  }

  tags = {
    Name = "cg-lambda-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}