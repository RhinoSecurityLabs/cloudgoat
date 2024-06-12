resource "aws_iam_role" "ec2_meek_role" {
  name        = "cg-ec2-meek-role-${var.cgid}"
  description = "cg meek ec2 role"

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
    Name = "CloudGoat ${var.cgid} EC2 Meek Role"
  })
}

resource "aws_iam_policy" "ec2_meek_policy" {
  name        = "cg-ec2-meek-policy"
  description = "cg-ec2-meek-policy"

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

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} EC2 Meek Policy"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_meek_policy_attachment" {
  role       = aws_iam_role.ec2_meek_role.name
  policy_arn = aws_iam_policy.ec2_meek_policy.arn
}

resource "aws_iam_instance_profile" "ec2_meek" {
  name = "cg-ec2-meek-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_meek_role.name
}