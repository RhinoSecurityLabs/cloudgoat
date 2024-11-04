data "archive_file" "cg-lambda-function" {
  type        = "zip"
  source_file = "../assets/lambda_function.py"
  output_path = "../assets/lambda_function.zip"
}

resource "aws_lambda_function" "charging_cash_lambda" {
  function_name = "${var.cgid}-lambda_function"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.cg-sqs_lambda_role.arn
  runtime       = "python3.11"

  filename         = data.archive_file.cg-lambda-function.output_path
  source_code_hash = filebase64sha256(data.archive_file.cg-lambda-function.output_path)

  timeout = 15

  environment {
    variables = {
      web_url    = "http://${aws_instance.cg_flag_shop_server.private_ip}:5000/sqs_process"
      auth = var.sqs_auth
    }
  }

  vpc_config {
    subnet_ids = [aws_subnet.cg-public-subnet-1.id]
    security_group_ids = [
      aws_security_group.cg-ec2-security-group.id
    ]
  }
}
