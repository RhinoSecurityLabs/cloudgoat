resource "aws_sqs_queue" "cg_cash_charge" {
  name                      = "cash-charging-queue"
  delay_seconds             = 0
  max_message_size          = 1024
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  sqs_managed_sse_enabled   = true
}

data "aws_iam_policy_document" "sqs_full_access" {
  statement {
    sid    = "AllowSQSFullAccess"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = ["*"]
  }
}

resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.cg_cash_charge.id
  policy    = data.aws_iam_policy_document.sqs_full_access.json
}

# SQS 대기열에서 람다로 메시지를 전달하기 위한 이벤트 소스 매핑 설정
resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = aws_sqs_queue.cg_cash_charge.arn
  function_name    = aws_lambda_function.charging_cash_lambda.arn
  batch_size       = 1 # 필요에 따라 조절 가능
}