# 1. Starting User
# Attack Path: Starts here. Can Describe EC2 to find User Data.
resource "aws_iam_user" "start_user" {
  name = "cg-start-user-${var.cgid}"
  tags = {
    Name = "cg-start-user-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_access_key" "start_user" {
  user = aws_iam_user.start_user.name
}

resource "aws_iam_user_policy" "start_user_policy" {
  name = "cg-start-user-policy-${var.cgid}"
  user = aws_iam_user.start_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. EC2 Instance Role
# Attack Path: Acquired via Metadata (IMDS). Can read Lambda details.
resource "aws_iam_role" "ec2_role" {
  name = "cg-ec2-role-${var.cgid}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
  tags = {
    Name = "cg-ec2-role-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name = "cg-ec2-policy-${var.cgid}"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}

# 3. Hidden User (Stored in Lambda)
# Attack Path: Credentials found in Lambda Env Vars. Can read Secrets.
resource "aws_iam_user" "lambda_user" {
  name = "cg-lambda-user-${var.cgid}"
  tags = {
    Name = "cg-lambda-user-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_access_key" "lambda_user" {
  user = aws_iam_user.lambda_user.name
}

resource "aws_iam_user_policy" "lambda_user_policy" {
  name = "cg-lambda-user-policy-${var.cgid}"
  user = aws_iam_user.lambda_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}