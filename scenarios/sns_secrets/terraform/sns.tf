# Create SNS Topic
resource "aws_sns_topic" "public_topic" {
  name = "public-topic-${var.cgid}"
}

# SNS Topic Policy to allow public access
resource "aws_sns_topic_policy" "public_topic_policy" {
  arn = aws_sns_topic.public_topic.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "sns:Subscribe",
          "sns:Receive",
          "sns:ListSubscriptionsByTopic"
        ]
        Resource = aws_sns_topic.public_topic.arn
      }
    ]
  })
}
