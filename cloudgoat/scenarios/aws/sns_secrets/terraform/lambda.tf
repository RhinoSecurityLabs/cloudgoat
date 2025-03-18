resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/cg-sns-secrets-${var.cgid}"
  retention_in_days = 1
  skip_destroy      = false
}

resource "aws_lambda_function" "sns_publisher" {
  function_name = "cg-sns-secrets-${var.cgid}"
  description   = "Pubishes API gateway secrets to SNS"
  runtime       = "python3.12"
  package_type  = "Zip"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda.handler"
  memory_size   = 128
  timeout       = 63

  source_code_hash = data.archive_file.lambda_code.output_base64sha256
  filename         = data.archive_file.lambda_code.output_path

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  environment {
    variables = {
      API_GATEWAY_KEY = aws_api_gateway_api_key.api_key.value
      SNS_ARN         = aws_sns_topic.public_topic.arn
    }
  }
}


resource "aws_cloudwatch_event_rule" "lambda_cron_trigger" {
  name                = "cg-sns-secrets-${var.cgid}"
  description         = "Triggers the CloudGoat sns lambda function every 2 minutes"
  schedule_expression = "rate(2 minutes)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  arn  = aws_lambda_function.sns_publisher.arn
  rule = aws_cloudwatch_event_rule.lambda_cron_trigger.name
}

resource "aws_lambda_permission" "allow_eventbridge_trigger" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_publisher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_cron_trigger.arn
}
