resource "aws_codebuild_project" "deploy-lambda" {
  name         = "deploy-lambda-function"
  service_role = aws_iam_role.deploy-lambda.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = aws_ecr_repository.app.repository_url
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = module.lambda_function_container_image.lambda_function_name
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/../assets/cd-pipeline/buildspec.yml")
  }
}


resource "aws_iam_role" "deploy-lambda" {
  name = "deploy-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "deploy-lambda" {
  role = aws_iam_role.deploy-lambda.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode"
      ],
      "Resource": [
          "${module.lambda_function_container_image.lambda_function_arn}"
      ]
    }
  ]
}
POLICY
}