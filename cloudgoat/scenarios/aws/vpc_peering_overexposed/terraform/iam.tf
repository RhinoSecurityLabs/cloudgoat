## IAM Configuration for vpc_peering_overexposed scenario

# Initial user with limited permissions for the assumed breach scenario
resource "aws_iam_user" "initial_user" {
  name = "${var.initial_username}-${var.cgid}"
}

resource "aws_iam_user_policy" "initial_user_policy" {
  name = "initial-user-policy-${var.cgid}"
  user = aws_iam_user.initial_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcPeeringConnections"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "initial_user_key" {
  user = aws_iam_user.initial_user.name
}

# Role for Dev EC2 - Intentionally over-permissioned
resource "aws_iam_role" "dev_ec2_role" {
  name = "dev-ec2-role-${var.cgid}"

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
    Name = "dev-ec2-role-${var.cgid}"
  }
}

# Policy for Dev EC2 with excessive permissions for lateral movement
resource "aws_iam_role_policy" "dev_ec2_policy" {
  name = "dev-ec2-policy-${var.cgid}"
  role = aws_iam_role.dev_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcPeeringConnections",
          "ssm:StartSession",
          "ssm:DescribeInstanceInformation",
          "ssm:GetConnectionStatus",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for Dev EC2
resource "aws_iam_instance_profile" "dev_ec2_profile" {
  name = "dev-ec2-profile-${var.cgid}"
  role = aws_iam_role.dev_ec2_role.name
}

# Role for Prod EC2 - Minimal permissions
resource "aws_iam_role" "prod_ec2_role" {
  name = "prod-ec2-role-${var.cgid}"

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
    Name = "prod-ec2-role-${var.cgid}"
  }
}

# Policy for Prod EC2 with minimal permissions
resource "aws_iam_role_policy" "prod_ec2_policy" {
  name = "prod-ec2-policy-${var.cgid}"
  role = aws_iam_role.prod_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for Prod EC2
resource "aws_iam_instance_profile" "prod_ec2_profile" {
  name = "prod-ec2-profile-${var.cgid}"
  role = aws_iam_role.prod_ec2_role.name
}

# SSM permissions to allow Session Manager access
resource "aws_iam_policy" "ssm_policy" {
  name        = "ssm-policy-${var.cgid}"
  description = "Allow SSM Session Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations",
          "ssm:ListAssociations",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:GetMessages",
          "ec2messages:SendReply",
          "ec2messages:GetEndpoint",
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:DescribeSessions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prod_ec2_ssm_policy" {
  role       = aws_iam_role.prod_ec2_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "dev_ec2_ssm_policy" {
  role       = aws_iam_role.dev_ec2_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
} 