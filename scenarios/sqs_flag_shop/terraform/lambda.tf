data "archive_file" "cg-lambda-function" {
  type        = "zip"
  source_file = "../assets/lambda_function.py"
  output_path = "../assets/lambda_function.zip"
}

resource "aws_lambda_function" "charging_cash_lambda" {
  function_name = "lambda_function"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.cg-sqs_lambda_role.arn
  runtime       = "python3.11"

  filename         = data.archive_file.cg-lambda-function.output_path
  source_code_hash = filebase64sha256(data.archive_file.cg-lambda-function.output_path)

  timeout = 3

  environment {
    variables = {
      web_url    = "http://${aws_instance.cg_flag_shop_server.public_ip}:5000/sqs_process"
      auth = var.sqs_auth
    }
  }
}