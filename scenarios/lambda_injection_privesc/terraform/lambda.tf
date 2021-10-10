#role-creator-lambda
resource "aws_iam_role" "policy_applier_lambda" {
  name = "cg-${var.cgid}-policy_applier_lambda"

  inline_policy {
    name = "policy_applier_lambda"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "iam:AttachUserPolicy"
          Effect   = "Allow"
          Resource = aws_iam_user.bilbo.arn
        },
        {
          Action   = "s3:GetObject"
          Effect   = "Allow"
          Resource = "*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:*:*"
            ]
        }
      ]
    })
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "policy_applier_lambda_zip" {
  type        = "zip"
  source_dir  = "lambda_source_code/policy_applier_lambda_src"
  output_path = "lambda_source_code/archives/policy_applier_lambda_src.zip"
}

resource "aws_lambda_function" "policy_applier_lambda" {
  filename      = data.archive_file.policy_applier_lambda_zip.output_path
  function_name = "cg-${var.cgid}-policy_applier_lambda"
  role          = aws_iam_role.policy_applier_lambda.arn
  handler       = "main.handler"
  description   =  "This function will apply a managed policy to the user of your choice, so long as the database says that it's okay..."
  source_code_hash = filebase64sha256(data.archive_file.policy_applier_lambda_zip.output_path)
  runtime = "python3.9"
}



#invocation-target-lambda1
resource "aws_iam_role" "target_lambda1" {
  name = "cg-${var.cgid}-target_lambda1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "target_lambda1_zip" {
    type        = "zip"
    source_dir  = "lambda_source_code/target_lambda1_src"
    output_path = "lambda_source_code/archives/target_lambda1_src.zip"
}

resource "aws_lambda_function" "target_lambda1" {
  filename      = data.archive_file.target_lambda1_zip.output_path
  function_name = "cg-${var.cgid}-target_lambda1"
  role          = aws_iam_role.target_lambda1.arn
  handler       = "main.handler"
  description   = "Invoke this function correctly and you win this scenario."
  source_code_hash = filebase64sha256(data.archive_file.target_lambda1_zip.output_path)
  runtime = "python3.9"
}


#invocation-target-lambda2
resource "aws_iam_role" "target_lambda2" {
  name = "cg-${var.cgid}-target_lambda2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "target_lambda2_zip" {
    type        = "zip"
    source_dir  = "lambda_source_code/target_lambda2_src"
    output_path = "lambda_source_code/archives/target_lambda2_src.zip"
}

resource "aws_lambda_function" "target_lambda2" {
  filename      = data.archive_file.target_lambda2_zip.output_path
  function_name = "cg-${var.cgid}-target_lambda2"
  role          = aws_iam_role.target_lambda2.arn
  handler       = "main.handler"
  description   = "Invoke this function correctly and you win this scenario."
  source_code_hash = filebase64sha256(data.archive_file.target_lambda2_zip.output_path)
  runtime = "python3.9"
}