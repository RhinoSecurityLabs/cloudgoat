resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda-${var.cgid}"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
          Effect = "Allow"
          Sid    = ""
        }
      ]
    }
  )

  managed_policy_arns = [
    aws_iam_policy.cognito-policy.arn
  ]
}

resource "aws_iam_policy" "cognito-policy" {
  name        = "cognito-policy-${var.cgid}"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "cognito-idp:*"
          ]
          Resource = "*"
          Effect   = "Allow"
        }
      ]
    }
  )
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "../assets/cognito-lambda.zip"
  function_name = "CognitoCTF-${var.cgid}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../assets/cognito-lambda.zip")

  runtime = "python3.9"
}

resource "aws_lambda_permission" "allow_cognitoidp" {
  statement_id  = "AllowExecutionFromCognitoIDP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
}
