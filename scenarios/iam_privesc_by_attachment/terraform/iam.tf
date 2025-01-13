resource "aws_iam_user" "kerrigan" {
  name          = "kerrigan"
  force_destroy = true
}

resource "aws_iam_access_key" "kerrigan" {
  user = aws_iam_user.kerrigan.name
}

resource "aws_iam_policy" "kerrigan_policy" {
  name        = "cg-kerrigan-policy"
  description = "CloudGoat ${var.cgid} kerrigan policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "iam:PassRole",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Action = [
          "ec2:AssociateIamInstanceProfile",
          "ec2:CreateKeyPair",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:RunInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "kerrigan_attachment" {
  user       = aws_iam_user.kerrigan.name
  policy_arn = aws_iam_policy.kerrigan_policy.arn
}
