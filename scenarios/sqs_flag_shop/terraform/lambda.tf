locals {
  function_name = "cache-charge"
}


resource "aws_lambda_function" "charging_cash_lambda" {
  function_name = "${local.function_name}-${var.cgid}"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.sqs_lambda.arn
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)

  timeout = 15

  environment {
    variables = {
      web_url = "http://${aws_instance.flag_shop_server.private_ip}:5000/sqs_process"
      auth    = var.sqs_auth
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.public_1.id
    ]

    security_group_ids = [
      aws_security_group.lambda.id
    ]
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name         = "/aws/lambda/${local.function_name}-${var.cgid}"
  skip_destroy = false
}
