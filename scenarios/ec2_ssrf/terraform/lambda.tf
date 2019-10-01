data "archive_file" "cg-lambda-function" {
  type = "zip"
  source_file = "../assets/lambda.py"
  output_path = "../assets/lambda.zip"
}
resource "aws_iam_role" "cg-lambda-role" {
  name = "cg-lambda-role-${var.cgid}-service-role"
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
    Name = "cg-lambda-role-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_lambda_function" "cg-lambda-function" {
  filename = "../assets/lambda.zip"
  function_name = "cg-lambda-${var.cgid}"
  role = "${aws_iam_role.cg-lambda-role.arn}"
  handler = "lambda.handler"
  source_code_hash = "${data.archive_file.cg-lambda-function.output_base64sha256}"
  runtime = "python3.6"
  environment {
      variables = {
          EC2_ACCESS_KEY_ID = "${aws_iam_access_key.cg-wrex.id}"
          EC2_SECRET_KEY_ID = "${aws_iam_access_key.cg-wrex.secret}"
      }
  }
  tags = {
    Name = "cg-lambda-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}