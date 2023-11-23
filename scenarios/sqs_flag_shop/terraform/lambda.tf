resource "aws_lambda_function" "charging_cash_lambda" {
  function_name = "lambda_function"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.sqs_rds_lambda_role.arn
  runtime       = "python3.11"

  filename         = "${path.module}/../assets/charging_cash_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../assets/charging_cash_lambda.zip")

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
      DB_NAME     = var.rds-database-name
      DB_USER     = var.rds_username
      DB_PASSWORD = var.rds_password
      DB_HOST     = aws_db_instance.cg-rds.address
      QueueUrl    = aws_sqs_queue.cg_cash_charge.url
    }
  }
}

#resource "aws_lambda_permission" "" {
#  statement_id  = "s3-trigger-permission"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.s3_to_gluecatalog.arn
#  principal     = "s3.amazonaws.com"
#  source_arn    = aws_s3_bucket.cg-data-from-web.arn
#}