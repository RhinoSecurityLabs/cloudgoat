resource "aws_sqs_queue" "cash_charge" {
  name                      = "cash_charging_queue"
  delay_seconds             = 0
  max_message_size          = 1024
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  sqs_managed_sse_enabled   = true
}

resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = aws_sqs_queue.cash_charge.arn
  function_name    = aws_lambda_function.charging_cash_lambda.arn
  batch_size       = 1
}
