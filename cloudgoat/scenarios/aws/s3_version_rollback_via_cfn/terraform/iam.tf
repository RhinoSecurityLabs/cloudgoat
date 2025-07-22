resource "aws_iam_user" "web_manager" {
  name = "web_manager-${var.cgid}"
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
        Sid: "IAMReadAccess",
        Effect: "Allow",
        Action: [
          "iam:List*",
          "iam:Get*"
        ],
        Resource: "*"
      },
      {
        Sid: "S3ReadOnly",
        Effect: "Allow",
        Action: [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucketVersions",
          "s3:GetObjectRetention"
        ],
        Resource: "arn:aws:s3:::cg-s3-version-index-*"
      },
      {
        Sid: "DenyPutObjectOnBypassBucket",
        Effect: "Deny",
        Action: "s3:PutObject",
        Resource: "arn:aws:s3:::cg-s3-version-index-*/*"
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
        Sid: "CloudFormationAccess",
        Effect: "Allow",
        Action: [
          "cloudformation:CreateStack",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents"
        ],
        Resource = "arn:aws:cloudformation:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:stack/*/*"
      },
      {
        Sid: "LambdaInvokeAllow",
        Effect: "Allow",
        Action: "lambda:InvokeFunction",
        Resource: "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:*"
      },
      {
        Sid: "AllowUseOfCFExecutionRole",
        Effect: "Allow",
        Action: [
          "iam:PassRole",
          "iam:GetRole"
        ],
        Resource: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CloudFormationRole-${var.cgid}"
      },
      {
        Sid: "AllowPassLambdaExecutionRole",
        Effect: "Allow",
        Action: [
          "iam:PassRole",
          "iam:GetRole"
        ],
        Condition: {
          "ForAnyValue:StringEquals" = {
            "aws:CalledVia" = "cloudformation.amazonaws.com"
          }
        },
        Resource: "arn:aws:iam::${data.aws_region.current.id}:role/LambdaPutObjectRole-${var.cgid}"
      }
    ]
  })
}

resource "aws_iam_role" "cloudformation_role" {
  name = "CloudFormationRole-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudformation.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudformation_role_policy" {
  name = "CloudFormationInlinePolicy-${var.cgid}"
  role = aws_iam_role.cloudformation_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:DeleteFunction",
          "iam:PassRole"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = "arn:aws:iam::912894834267:role/LambdaPutObjectRole-${var.cgid}",
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "lambda_putobject_role" {
  name = "LambdaPutObjectRole-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_putobject_policy" {
  name = "LambdaPutObjectPolicy-${var.cgid}"
  role = aws_iam_role.lambda_putobject_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::cg-s3-version-index-*/*"
      }
    ]
  })
}