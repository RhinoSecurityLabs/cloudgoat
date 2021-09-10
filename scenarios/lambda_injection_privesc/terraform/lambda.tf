#role-creator-lambda
resource "aws_iam_role" "role_creator_lambda" {
  name = "cg-${var.cgid}-role_creator_lambda"
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
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

data "archive_file" "role_creator_lambda_zip" {
    type        = "zip"
    source_dir  = "lambda_source_code/role_creator_lambda_src"
    output_path = "lambda_source_code/archives/role_creator_lambda_src.zip"
}

resource "aws_lambda_function" "role_creator_lambda" {
  filename      = "${data.archive_file.role_creator_lambda_zip.output_path}"
  function_name = "cg-${var.cgid}-role_creator_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler"
  source_code_hash = filebase64sha256("${data.archive_file.role_creator_lambda_zip.output_path}")
  runtime = "python3.9"
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}



#invokation-target-lambda
resource "aws_iam_role" "invocation_target_lambda" {
  name = "cg-${var.cgid}-invocation_target_lambda"
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
  tags = {
      Name     = "cg-${var.cgid}"
      Stack    = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
    }
}

data "archive_file" "invocation_target_lambda_zip" {
    type        = "zip"
    source_dir  = "lambda_source_code/invocation_target_lambda_src"
    output_path = "lambda_source_code/archives/invocation_target_lambda_src.zip"
}

resource "aws_lambda_function" "invocation_target_lambda" {
  filename      = "${data.archive_file.invocation_target_lambda_zip.output_path}"
  function_name = "cg-${var.cgid}-invocation_target_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler"
  source_code_hash = filebase64sha256("${data.archive_file.invocation_target_lambda_zip.output_path}")
  runtime = "python3.9"
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}