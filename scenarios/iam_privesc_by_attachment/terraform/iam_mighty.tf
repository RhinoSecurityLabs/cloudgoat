resource "aws_iam_role" "ec2_mighty_role" {
  name        = "cg-ec2-mighty-role-${var.cgid}"
  description = "CloudGoat ${var.cgid} EC2 Mighty Role"

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
    aws_iam_policy.ec2_mighty_policy.arn
  ]
}

resource "aws_iam_policy" "ec2_mighty_policy" {
  name        = "cg-ec2-mighty-policy"
  description = "CloudGoat ${var.cgid} EC2 Mighty Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
