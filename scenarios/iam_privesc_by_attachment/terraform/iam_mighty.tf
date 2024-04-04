resource "aws_iam_role" "ec2_mighty_role" {
  name        = "cg-ec2-mighty-role-${var.cgid}"
  description = "cg mighty ec2 role"

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

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} EC2 Mighty Role"
  })
}

resource "aws_iam_policy" "ec2_mighty_policy" {
  name        = "cg-ec2-mighty-policy"
  description = "cg-ec2-mighty-policy"

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

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} EC2 Mighty Policy"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_mighty_policy_attachment" {
  role       = aws_iam_role.ec2_mighty_role.name
  policy_arn = aws_iam_policy.ec2_mighty_policy.arn
}
