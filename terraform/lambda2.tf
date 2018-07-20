resource "aws_iam_role" "lambda_iam_2" {
  name = "iam_for_lambda_2"

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

resource "aws_lambda_function" "lambda_2" {
  filename         = "lambda_function_2.zip"
  function_name    = "lambda_function_2"
  role             = "${aws_iam_role.lambda_iam_2.arn}"
  handler          = "exports.test"
  source_code_hash = "${base64sha256(file("lambda_function_2.zip"))}"
  runtime          = "nodejs4.3"
}
