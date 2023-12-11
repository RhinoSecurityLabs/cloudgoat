#cg-run-app == glue_web
resource "aws_iam_user" "cg-run-app" {
  name = "cg-run-app-${var.cgid}"
  tags = {
    Name     = "cg-run-app-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}


resource "aws_iam_access_key" "cg-run-app_access_key" {
  user = aws_iam_user.cg-run-app.name
}


resource "aws_iam_policy_attachment" "user_RDS_full_access" {
  name       = "RDSFullAccessAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  users      = [aws_iam_user.cg-run-app.name]
}


resource "aws_iam_user" "cg-glue-admin" {
  name = "cg-glue-admin-${var.cgid}"
  tags = {
    Name     = "cg-glue-admin-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}


data "aws_s3_bucket" "cg-data-from-web" {
  bucket = aws_s3_bucket.cg-data-from-web.id
}

resource "aws_iam_user_policy" "glue_management_policy" {
  name = "glue_management_policy"
  user = aws_iam_user.cg-glue-admin.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "glue:CreateJob",
          "iam:PassRole",
          "iam:Get*",
          "iam:List*",
          "glue:CreateTrigger",
          "glue:StartJobRun",
          "glue:UpdateJob"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : data.aws_s3_bucket.cg-data-from-web.arn
      }
    ]
  })
}


resource "aws_iam_access_key" "cg-glue-admin_access_key" {
  user = aws_iam_user.cg-glue-admin.name
}

resource "aws_iam_role" "glue_ETL_role" {
  name = "glue_ETL_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "rds.amazonaws.com",
          "glue.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

locals {
  gEr_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]

  spr_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  ]

  stglr_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "glue_ETL_role_policies" {
  for_each   = toset(local.gEr_policy_arns)
  role       = aws_iam_role.glue_ETL_role.name
  policy_arn = each.value
}

resource "aws_iam_role" "ssm_parameter_role" {
  name = "ssm_parameter_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "glue.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_parameter_role_policies" {
  for_each   = toset(local.spr_policy_arns)
  role       = aws_iam_role.ssm_parameter_role.name
  policy_arn = each.value
}

resource "aws_iam_role" "s3_to_gluecatalog_lambda_role" {
  name = "s3_to_gluecatalog_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "Lambda_Basic_Execution" {
  role       = aws_iam_role.s3_to_gluecatalog_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_to_gluecatalog_lambda_role_policies" {
  for_each   = toset(local.stglr_policy_arns)
  role       = aws_iam_role.s3_to_gluecatalog_lambda_role.name
  policy_arn = each.value
}


data "aws_iam_policy_document" "ec2_profile_data" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_profile_role" {
  name               = "cg-${var.scenario-name}-ec2-profile"
  assume_role_policy = data.aws_iam_policy_document.ec2_profile_data.json
}

resource "aws_iam_instance_profile" "cg-ec2-instance-profile" {
  name = "cg-${var.scenario-name}-${var.cgid}-ecs-agent"
  role = aws_iam_role.ec2_profile_role.name
}

resource "aws_iam_policy" "s3_put_policy" {
  name = "s3_put_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutBucketPolicy"
        ],
        "Resource" : aws_s3_bucket.cg-data-from-web.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "s3_put_attche" {
  policy_arn = aws_iam_policy.s3_put_policy.arn
  user       = aws_iam_user.cg-run-app.name
}