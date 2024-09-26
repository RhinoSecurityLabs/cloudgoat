resource "aws_iam_user" "glue_web" {
  name = "cg-run-app-${var.cgid}"
}

resource "aws_iam_access_key" "glue_web_access_key" {
  user = aws_iam_user.glue_web.name
}

resource "aws_iam_policy" "s3_put_policy" {
  name        = "s3_put_policy"
  description = "Policy for putting objects in S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Put"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutBucketPolicy"
        ]
        Resource = aws_s3_bucket.web.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "s3_put_object" {
  policy_arn = aws_iam_policy.s3_put_policy.arn
  user       = aws_iam_user.glue_web.name
}

resource "aws_iam_user_policy_attachment" "user_rds_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  user       = aws_iam_user.glue_web.name
}


resource "aws_iam_user" "glue_admin" {
  name = "cg-glue-admin-${var.cgid}"
}

resource "aws_iam_user_policy" "glue_management_policy" {
  name = "glue_management_policy"
  user = aws_iam_user.glue_admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMGlueManagement"
        Effect = "Allow"
        Action = [
          "glue:CreateJob",
          "glue:CreateTrigger",
          "glue:StartJobRun",
          "glue:UpdateJob",
          "iam:PassRole",
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.web.arn
      }
    ]
  })
}

resource "aws_iam_access_key" "glue_admin_access_key" {
  user = aws_iam_user.glue_admin.name
}


resource "aws_iam_role" "glue_ETL_role" {
  name        = "glue_ETL_role"
  description = "Role for Glue ETL jobs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "rds.amazonaws.com",
            "glue.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
}


resource "aws_iam_role" "ssm_parameter_role" {
  name = "ssm_parameter_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  ]
}


resource "aws_iam_role" "s3_to_gluecatalog_lambda_role" {
  name        = "s3_to_gluecatalog_lambda_role"
  description = "Role for Lambda function that loads data into Glue Catalog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}


resource "aws_iam_role" "ec2_role" {
  name        = "cg-${var.scenario-name}-ec2-profile"
  description = "Role for EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "ec2" {
  name = "cg-${var.scenario-name}-${var.cgid}-ecs-agent"
  role = aws_iam_role.ec2_role.name
}
