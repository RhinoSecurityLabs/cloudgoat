# iam.tf

# 1. EC2 IAM ROLE
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
    Stack = var.stack_name
    Scenario = var.scenario_name
  }
}

# 2. EC2 ROLE POLICY (The Vulnerability)
resource "aws_iam_role_policy" "ec2_policy" {
  name = "cg-ec2-policy-${var.cgid}"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListingAssets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::cg-assets-${var.cgid}"
      },
      {
        Sid    = "AllowSyncingAssets"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",       
          "s3:DeleteObject"     
        ]
        Resource = "arn:aws:s3:::cg-assets-${var.cgid}/*"
      }
    ]
  })
}

# 3. INSTANCE PROFILE
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}