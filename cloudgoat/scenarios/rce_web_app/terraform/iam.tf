#IAM Users
resource "aws_iam_user" "cg-lara" {
  name = "lara"
  tags = merge(local.default_tags, {
    Name = "cg-lara-${var.cgid}"
  })
}

resource "aws_iam_access_key" "cg-lara" {
  user = aws_iam_user.cg-lara.name
}

resource "aws_iam_user" "cg-mcduck" {
  name = "McDuck"
  tags = merge(local.default_tags, {
    Name = "cg-mcduck-${var.cgid}"
  })
}

resource "aws_iam_access_key" "cg-mcduck" {
  user = aws_iam_user.cg-mcduck.name
}

#IAM User Policies
resource "aws_iam_policy" "cg-lara-policy" {
  name        = "cg-lara-s3-policy"
  description = "cg-lara-policy"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action   = "s3:ListBucket"
          Effect   = "Allow"
          Resource = "arn:aws:s3:::cg-logs-s3-bucket-${local.cgid_suffix}"
        },
        {
          Action   = "s3:GetObject"
          Effect   = "Allow"
          Resource = "arn:aws:s3:::cg-logs-s3-bucket-${local.cgid_suffix}/*"
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
    }
  )

  tags = merge(local.default_tags, {
    Name = "cg-lara-s3-policy-${var.cgid}"
  })
}
resource "aws_iam_policy" "cg-mcduck-policy" {
  name        = "cg-mcduck-s3-policy"
  description = "cg-mcduck-policy"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action   = "s3:ListBucket"
          Effect   = "Allow"
          Resource = "arn:aws:s3:::cg-keystore-s3-bucket-${local.cgid_suffix}"
        },
        {
          Action   = "s3:GetObject"
          Effect   = "Allow"
          Resource = "arn:aws:s3:::cg-keystore-s3-bucket-${local.cgid_suffix}/*"
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
    }
  )

  tags = merge(local.default_tags, {
    Name = "cg-mcduck-s3-policy-${var.cgid}"
  })
}

#IAM User Policy Attachments
resource "aws_iam_user_policy_attachment" "cg-lara-attachment" {
  user       = aws_iam_user.cg-lara.name
  policy_arn = aws_iam_policy.cg-lara-policy.arn
}

resource "aws_iam_user_policy_attachment" "cg-mcduck-attachment" {
  user       = aws_iam_user.cg-mcduck.name
  policy_arn = aws_iam_policy.cg-mcduck-policy.arn
}