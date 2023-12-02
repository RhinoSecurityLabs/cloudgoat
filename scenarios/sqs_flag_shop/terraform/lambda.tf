resource "aws_lambda_function" "charging_cash_lambda" {
  function_name = "lambda_function"
  handler       = "charging_cash_lambda/lambda_function.lambda_handler"
  role          = aws_iam_role.cg-sqs_lambda_role.arn
  runtime       = "python3.11"

  filename         = "${path.module}/../assets/lambda_function.py"
  source_code_hash = filebase64sha256("${path.module}/../assets/lambda_funtion.py")

  depends_on = [aws_vpc.cg-vpc]

  vpc_config {
    subnet_ids = [
      aws_subnet.cg-private-subnet-1.id,
      aws_subnet.cg-private-subnet-2.id
    ]
    security_group_ids = [aws_security_group.cg-rds-security-group.id]
  }
  timeout = 10

  environment {
    variables = {
      web_url    = "${aws_instance.cg_flag_shop_server.public_ip}:5000"
    }
  }
}