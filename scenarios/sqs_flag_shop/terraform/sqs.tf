resource "aws_sqs_queue" "cg_cash_charge" {
  name                      = "terraform-example-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = 4
  })
}


data "aws_iam_policy_document" "test" {
  statement {
    sid    = "First"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.cg_cash_charge.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.example.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.cg_cash_charge.id
  policy    = data.aws_iam_policy_document.test.json
}

# SQS 대기열에서 람다로 메시지를 전달하기 위한 이벤트 소스 매핑 설정
resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = aws_sqs_queue.cg_cash_charge.arn
  function_name    = aws_lambda_function.processing_data.arn
  batch_size       = 5  # 필요에 따라 조절 가능
}