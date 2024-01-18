resource "aws_cloudwatch_log_group" "cg-cloudwatch-log-group" {
  name = "/aws/lambda/${var.cgid}-lambda_function"
}