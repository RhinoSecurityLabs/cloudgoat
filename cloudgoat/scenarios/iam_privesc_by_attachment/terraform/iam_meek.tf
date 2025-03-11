resource "aws_iam_role" "ec2_meek_role" {
  name        = "cg-ec2-meek-role-${var.cgid}"
  description = "CloudGoat ${var.cgid} EC2 Meek Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })

  managed_policy_arns = [
    aws_iam_policy.ec2_meek_policy.arn
  ]
}

resource "aws_iam_policy" "ec2_meek_policy" {
  name        = "cg-ec2-meek-policy"
  description = "CloudGoat ${var.cgid} EC2 Meek Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Deny"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_meek" {
  name = "cg-ec2-meek-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_meek_role.name
}
