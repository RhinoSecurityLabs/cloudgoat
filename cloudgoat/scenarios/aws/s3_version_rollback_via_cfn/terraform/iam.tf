resource "aws_iam_policy" "put_object_boundary" {
  name = "PutObjectBoundaryPolicy-${var.cgid}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowIAMRead",
        Effect = "Allow",
        Action = [
          "iam:List*",
          "iam:Get*"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowS3ReadOnly",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucketVersions",
          "s3:GetObjectRetention"
        ],
        Resource = "arn:aws:s3:::cg-s3-version-bypass-*"
      },
      {
        Sid    = "AllowPutObject",
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::cg-s3-version-bypass-*/*"
      },
      {
        Sid    = "AllowCloudFormation",
        Effect = "Allow",
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DescribeStacks",
          "cloudformation:GetTemplate"
        ],
        Resource = "arn:aws:cloudformation:*:*:stack/*/*"
      },
      {
        Sid    = "AllowLimitedRoleOps",
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:TagRole",
          "iam:PutRolePolicy",
          "iam:GetRole",
          "iam:PassRole"
        ],
        Resource = "arn:aws:iam::*:role/CloudFormationRole"
      },
      {
        Sid    = "AllowAssumeRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = "arn:aws:iam::*:role/CloudFormationRole"
      }
    ]
  })
}

resource "aws_iam_user" "web_manager" {
  name                 = "web_manager-${var.cgid}"
  permissions_boundary = aws_iam_policy.put_object_boundary.arn
}

resource "aws_iam_access_key" "web_manager_key" {
  user = aws_iam_user.web_manager.name
}

resource "aws_iam_user_policy" "web_manager_s3_policy" {
  name = "WebManagerS3Policy-${var.cgid}"
  user = aws_iam_user.web_manager.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "IAMReadAccess",
        Effect = "Allow",
        Action = ["iam:List*", "iam:Get*"],
        Resource = "*"
      },
      {
        Sid    = "S3ReadOnly",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucketVersions",
          "s3:GetObjectRetention"
        ],
        Resource = "arn:aws:s3:::cg-s3-version-bypass-*"
      },
      {
        Sid    = "DenyPutObjectOnBypassBucket",
        Effect = "Deny",
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::cg-s3-version-bypass-*/*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "web_manager_role_policy" {
  name = "WebManagerRoleControlPolicy-${var.cgid}"
  user = aws_iam_user.web_manager.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "CloudFormationLimited",
        Effect = "Allow",
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DescribeStacks",
          "cloudformation:GetTemplate"
        ],
        Resource = "arn:aws:cloudformation:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:stack/*/*"
      },
      {
        Sid    = "AssumeAndPassOnlyExploitRole",
        Effect = "Allow",
        Action = [
          "sts:AssumeRole",
          "iam:PassRole",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:TagRole",
          "iam:PutRolePolicy"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CloudFormationRole"
      },
      {
        Sid    = "ForcePermissionsBoundaryOnCreateRole",
        Effect = "Deny",
        Action = "iam:CreateRole",
        Resource = "*",
        Condition = {
          StringNotEqualsIfExists = {
            "iam:PermissionsBoundary" = aws_iam_policy.put_object_boundary.arn
          }
        }
      }
    ]
  })
}
