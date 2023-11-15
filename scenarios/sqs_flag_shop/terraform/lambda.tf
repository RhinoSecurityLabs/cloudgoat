data "archive_file" "cg-lambda-function" {
  type        = "zip"
  source_file = "../assets/processing.py"
  output_path = "../assets/processing.zip"
}

resource "aws_lambda_function" "processing_data" {
  function_name = "processing"
  handler       = "processing.lambda_handler"
  role          = aws_iam_role.s3_to_gluecatalog_lambda_role.arn
  runtime       = "python3.11"

  filename         = data.archive_file.cg-lambda-function.output_path
  source_code_hash = filebase64sha256(data.archive_file.cg-lambda-function.output_path)

  timeout = 30

#  environment {
#    variables = {
#      BUCKET_Scenario2 = aws_s3_bucket.cg-data-from-web.id
#      BUCKET_Final     = aws_s3_bucket.cg-data-s3-bucket.id
#      JDBC_URL         = aws_glue_connection.cg-glue-connection.connection_properties.JDBC_CONNECTION_URL
#    }
#  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "s3-trigger-permission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_gluecatalog.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cg-data-from-web.arn
}