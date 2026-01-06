# Lara IAM User & Permissions
resource "aws_iam_user" "lara" {
  name = "lara"
}

resource "aws_iam_access_key" "lara" {
  user = aws_iam_user.lara.name
}

resource "aws_iam_policy" "lara" {
  name        = "cg-lara-s3-policy"
  description = "cg-lara-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.logs.arn}/*"
      },
      {
        Action   = "s3:ListAllMyBuckets"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "rds:DescribeDBInstances",
          "elasticloadbalancing:DescribeLoadBalancers"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "lara" {
  user       = aws_iam_user.lara.name
  policy_arn = aws_iam_policy.lara.arn
}



# McDuck IAM User & Permissions
resource "aws_iam_user" "mcduck" {
  name = "McDuck"
}

resource "aws_iam_access_key" "mcduck" {
  user = aws_iam_user.mcduck.name
}

resource "aws_iam_policy" "mcduck" {
  name        = "cg-mcduck-s3-policy"
  description = "cg-mcduck-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.keystore.arn
      },
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.keystore.arn}/*"
      },
      {
        Action   = "s3:ListAllMyBuckets"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "rds:DescribeDBInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "mcduck" {
  user       = aws_iam_user.mcduck.name
  policy_arn = aws_iam_policy.mcduck.arn
}
