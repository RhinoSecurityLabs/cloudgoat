# IAM Configuration for federated_console_takeover scenario

# Initial user with limited permissions
resource "aws_iam_user" "initial_user" {
  name = "cg-initial-user-${var.cgid}"
  
  tags = {
    Name = "cg-initial-user-${var.cgid}"
  }
}

resource "aws_iam_access_key" "initial_user" {
  user = aws_iam_user.initial_user.name
}

resource "aws_iam_user_policy" "initial_user_policy" {
  name = "cg-initial-user-policy-${var.cgid}"
  user = aws_iam_user.initial_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeIamInstanceProfileAssociations",
          "iam:ListRoles",
          "ssm:StartSession",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:TerminateSession"
        ]
        Resource = "arn:aws:ssm:*:*:session/$${aws:username}-*"
      }
    ]
  })
}

# EC2 Admin Role with elevated permissions
resource "aws_iam_role" "ec2_admin_role" {
  name = "cg-ec2-admin-role-${var.cgid}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name = "cg-ec2-admin-role-${var.cgid}"
  }
}

# EC2 Admin Role Policy
resource "aws_iam_role_policy" "ec2_admin_policy" {
  name = "cg-ec2-admin-policy-${var.cgid}"
  role = aws_iam_role.ec2_admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:GetUser",
          "ec2:*",
          "ssm:GetParameter*",
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the EC2 Role to an Instance Profile
resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = "cg-ec2-admin-profile-${var.cgid}"
  role = aws_iam_role.ec2_admin_role.name
}

# SSM Role Policy (allowing EC2 to communicate with SSM)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
} 