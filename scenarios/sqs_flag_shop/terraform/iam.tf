resource "aws_iam_user" "cg-web-sqs-manager" {
  name = "cg-web-sqs-manager-${var.cgid}"
  tags = {
    Name     = "cg-web-sqs-manager-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}


resource "aws_iam_access_key" "cg-web-sqs-manager_access_key" {
  user = aws_iam_user.cg-web-sqs-manager.name
}

resource "aws_iam_policy_attachment" "user_SQS_full_access" {
  name       = "SQSFullAccessAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  users      = [aws_iam_user.cg-web-sqs-manager.name]
}

resource "aws_iam_user" "cg-sqs-user" {
  name = "cg-sqs-user-${var.cgid}"
  tags = {
    Name     = "cg-sqs-user-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_access_key" "cg-sqs-user_access_key" {
  user = aws_iam_user.cg-sqs-user.name
}

resource "aws_iam_policy" "sqs_scenario_policy" {
  name = "sqs_scenario_policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "sqs:GetQueueUrl",
                "sqs:SendMessage"
            ],
            "Resource": aws_sqs_queue.cg_cash_charge.arn
        }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "sqs_scenario_attche" {
  policy_arn = aws_iam_policy.sqs_scenario_policy.arn
  user       = aws_iam_user.cg-sqs-user.name
}

resource "aws_iam_role" "sqs_rds_lambda_role" {
  name = "sqs_rds_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "sqs_send_msg_role" {
  name = "sqs_send_msg_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

locals {
  sqs_rds_lambda_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}

resource "aws_iam_role_policy_attachment" "sqs_rds_lambda_role_policies" {
  for_each   = toset(local.sqs_rds_lambda_role_policy_arns)
  role       = aws_iam_role.sqs_rds_lambda_role.name
  policy_arn = each.value
}
