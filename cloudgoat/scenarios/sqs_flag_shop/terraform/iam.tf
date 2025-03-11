resource "aws_iam_user" "web_sqs_manager" {
  name = "cg-web-sqs-manager-${var.cgid}"
}

resource "aws_iam_access_key" "web_sqs_manager" {
  user = aws_iam_user.web_sqs_manager.name
}

resource "aws_iam_policy_attachment" "user_sqs_full_access" {
  name       = "SQSFullAccessAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  users      = [aws_iam_user.web_sqs_manager.name]
}


resource "aws_iam_user" "sqs" {
  name = "cg-sqs-user-${var.cgid}"
}

resource "aws_iam_access_key" "sqs" {
  user = aws_iam_user.sqs.name
}

resource "aws_iam_user_policy" "sqs_scenario_assumed_role" {
  name = "cg-sqs-scenario-assumed-role"
  user = aws_iam_user.sqs.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.sqs_send_message.arn
      }
    ]
  })
}



resource "aws_iam_role" "sqs_lambda" {
  name = "cg-sqs-lambda-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "sqs_lambda" {
  role_name = aws_iam_role.sqs_lambda.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]
}


resource "aws_iam_role" "sqs_send_message" {
  name = "cg-sqs-send-message-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.sqs.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sqs_scenario" {
  name = "cg-sqs"
  role = aws_iam_role.sqs_send_message.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueUrl",
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.cash_charge.arn
      }
    ]
  })
}
