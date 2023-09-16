resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda-${var.cgid}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cognito-policy" {
  name        = "cognito-policy-${var.cgid}"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.cognito-policy.arn
}


resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "../assets/cognito-lambda.zip"
  function_name = "CognitoCTF-${var.cgid}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("../assets/cognito-lambda.zip")

  runtime = "python3.9"

  environment {
    variables = {
      foo = "bar"
    }
  }
}


resource "aws_lambda_permission" "allow_cognitoidp" {
  statement_id  = "AllowExecutionFromCognitoIDP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
}

