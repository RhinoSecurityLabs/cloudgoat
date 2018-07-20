resource "aws_iam_role" "lambda_iam_1" {
  name = "iam_for_lambda"

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

resource "aws_lambda_function" "lambda_1" {
  filename         = "lambda_function_1.zip"
  function_name    = "lambda_function_1"
  role             = "${aws_iam_role.lambda_iam_1.arn}"
  handler          = "exports.test"
  source_code_hash = "${base64sha256(file("lambda_function_1.zip"))}"
  runtime          = "nodejs4.3"
}
