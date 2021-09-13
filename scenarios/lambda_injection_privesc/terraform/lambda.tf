#role-creator-lambda
resource "aws_iam_role" "policy_applier_lambda" {
  name = "cg-${var.cgid}-policy_applier_lambda"
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

data "archive_file" "policy_applier_lambda_zip" {
    type        = "zip"
    source_dir  = "lambda_source_code/policy_applier_lambda_src"
    output_path = "lambda_source_code/archives/policy_applier_lambda_src.zip"
}

resource "aws_lambda_function" "policy_applier_lambda" {
  filename      = "${data.archive_file.policy_applier_lambda_zip.output_path}"
  function_name = "cg-${var.cgid}-policy_applier_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler"
  description   =  "This function will apply a managed policy to the user of your choice, so long as the database says that it's okay..."
  source_code_hash = filebase64sha256("${data.archive_file.policy_applier_lambda_zip.output_path}")
  runtime = "python3.9"
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}



#invokation-target-lambda
resource "aws_iam_role" "target_lambda" {
  name = "cg-${var.cgid}-target_lambda"
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

data "archive_file" "target_lambda_zip" {
    type        = "zip"
    source_dir  = "lambda_source_code/target_lambda_src"
    output_path = "lambda_source_code/archives/target_lambda_src.zip"
}

resource "aws_lambda_function" "target_lambda" {
  filename      = "${data.archive_file.target_lambda_zip.output_path}"
  function_name = "cg-${var.cgid}-target_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler"
  description   = "Invoke this function correctly and you win this scenario."
  source_code_hash = filebase64sha256("${data.archive_file.target_lambda_zip.output_path}")
  runtime = "python3.9"
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}