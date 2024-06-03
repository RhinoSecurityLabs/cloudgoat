# IAM Role for EC2
resource "aws_iam_role" "cg-ec2-sns-role" {
  name = "cg-ec2-sns-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# IAM Role Policy for EC2
resource "aws_iam_role_policy" "cg-ec2-sns-policy" {
  name   = "cg-ec2-sns-policy-${var.cgid}"
  role   = aws_iam_role.cg-ec2-sns-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish",
                "sns:Subscribe",
                "sns:Receive"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Attach the IAM Role to an EC2 instance
resource "aws_iam_instance_profile" "cg-ec2-sns-instance-profile" {
  name = "cg-ec2-sns-instance-profile-${var.cgid}"
  role = aws_iam_role.cg-ec2-sns-role.name
}

# IAM User for subscribing to SNS
resource "aws_iam_user" "cg-sns-user" {
  name = "cg-sns-user-${var.cgid}"
  tags = {
    Name = "cg-sns-user-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_user_policy" "cg-sns-user-policy" {
  name = "cg-sns-user-policy-${var.cgid}"
  user = aws_iam_user.cg-sns-user.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
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
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "apigateway:GET"
      ],
      "Resource": [
        "arn:aws:apigateway:us-east-1::/apikeys",
        "arn:aws:apigateway:us-east-1::/apikeys/*",
        "arn:aws:apigateway:us-east-1::/restapis/*/resources/*/methods/GET",
        "arn:aws:apigateway:us-east-1::/restapis/*/methods/GET",
        "arn:aws:apigateway:us-east-1::/restapis/*/resources/*/integration",
        "arn:aws:apigateway:us-east-1::/restapis/*/integration",
        "arn:aws:apigateway:us-east-1::/restapis/*/resources/*/methods/*/integration"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "cg-sns-user-key" {
  user = aws_iam_user.cg-sns-user.name
}
