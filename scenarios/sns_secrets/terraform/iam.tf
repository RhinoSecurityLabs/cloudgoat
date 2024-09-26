# IAM role used by the lambda function to publish to SNS
resource "aws_iam_role" "lambda" {
  name                 = "cg-sns-secrets-${var.cgid}"
  description          = "Allows Lambda to publish to SNS and write logs to CloudWatch"
  max_session_duration = 60 * 60

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "writeCloudWatchLogs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "writeCloudWatchLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "${aws_cloudwatch_log_group.lambda.arn}:log-stream:*"
        },
        {
          Sid      = "publishSNS"
          Effect   = "Allow"
          Action   = "sns:Publish"
          Resource = aws_sns_topic.public_topic.arn
        }
      ]
    })
  }
}


# IAM User for subscribing to SNS
resource "aws_iam_user" "sns_user" {
  name = "cg-sns-user-${var.cgid}"
}

resource "aws_iam_user_policy" "sns_user_policy" {
  name = "cg-sns-user-policy-${var.cgid}"
  user = aws_iam_user.sns_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe",
          "sns:Receive",
          "sns:ListSubscriptionsByTopic",
          "sns:ListTopics",
          "sns:GetTopicAttributes",
          "iam:ListGroupsForUser",
          "iam:ListUserPolicies",
          "iam:GetUserPolicy",
          "iam:ListAttachedUserPolicies",
          "apigateway:GET"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = "apigateway:GET"
        Resource = [
          "arn:aws:apigateway:${var.region}::/apikeys",
          "arn:aws:apigateway:${var.region}::/apikeys/*",
          "arn:aws:apigateway:${var.region}::/restapis/*/resources/*/methods/GET",
          "arn:aws:apigateway:${var.region}::/restapis/*/methods/GET",
          "arn:aws:apigateway:${var.region}::/restapis/*/resources/*/integration",
          "arn:aws:apigateway:${var.region}::/restapis/*/integration",
          "arn:aws:apigateway:${var.region}::/restapis/*/resources/*/methods/*/integration"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "sns_user_key" {
  user = aws_iam_user.sns_user.name
}
