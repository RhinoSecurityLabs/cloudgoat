data "archive_file" "lambda_code" {
  type        = "zip"
  output_path = "lambda.zip"
  source_file = "source/lambda.py"
}
