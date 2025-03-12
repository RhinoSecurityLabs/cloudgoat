# Role for EC2
resource "aws_iam_role" "ec2" {
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
}

# Role Policy for EC2
resource "aws_iam_role_policy" "ec2" {
  name = "cg-ec2-policy-${var.cgid}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the EC2 Role to an Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2.name
}


# Sample User 1
resource "aws_iam_user" "user1" {
  name = "cg-user1-${var.cgid}"
}

resource "aws_iam_user_policy" "user1" {
  name = "cg-user1-policy-${var.cgid}"
  user = aws_iam_user.user1.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "user1" {
  user = aws_iam_user.user1.name
}


# Sample User 2
resource "aws_iam_user" "user2" {
  name = "cg-user2-${var.cgid}"
}

resource "aws_iam_user_policy" "user2" {
  name = "cg-user2-policy-${var.cgid}"
  user = aws_iam_user.user2.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:ListTables",
          "dynamodb:DescribeTable"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "user2" {
  user = aws_iam_user.user2.name
}
