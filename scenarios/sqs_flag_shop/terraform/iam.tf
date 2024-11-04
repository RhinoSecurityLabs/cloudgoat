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

resource "aws_iam_role_policy" "cg-sqs_scenario_policy" {
  name = "cg-sqs_scenario_policy"
  role = aws_iam_role.cg-sqs_send_msg_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "sqs:GetQueueUrl",
          "sqs:SendMessage"
        ],
        "Resource" : aws_sqs_queue.cg_cash_charge.arn
      }
    ]
  })
}

resource "aws_iam_user_policy" "cg-sqs_scenario_assumed_role_policy" {
  name   = "cg-sqs-scenario-assumed-role-policy"
  user   = aws_iam_user.cg-sqs-user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "iam:Get*",
          "iam:List*",
        ],
        Resource = "*",
      },
      {
        Sid    = "VisualEditor1",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = aws_iam_role.cg-sqs_send_msg_role.arn,
      },
    ],
  })
}

resource "aws_iam_role" "cg-sqs_lambda_role" {
  name = "cg-sqs_rds_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.cg-sqs_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "cg-sqs_send_msg_role" {
  name = "cg-sqs_send_msg_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_user.cg-sqs-user.arn}"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
EOF
}

locals {
  sqs_lambda_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
}

resource "aws_iam_role_policy_attachment" "sqs_lambda_role_policies" {
  for_each   = toset(local.sqs_lambda_role_policy_arns)
  role       = aws_iam_role.cg-sqs_lambda_role.name
  policy_arn = each.value
}
