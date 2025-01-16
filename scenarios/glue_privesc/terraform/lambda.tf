resource "aws_lambda_function" "s3_to_gluecatalog" {
  function_name = "s3_to_gluecatalog"
  description   = "This lambda function is triggered by an S3 event and loads data into Glue Catalog"
  handler       = "s3_to_gluecatalog.lambda_handler"
  role          = aws_iam_role.s3_to_gluecatalog_lambda_role.arn
  runtime       = "python3.12"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout = 180

  environment {
    variables = {
      BUCKET_Scenario2 = aws_s3_bucket.web.id
      BUCKET_Final     = aws_s3_bucket.data.id
      JDBC_URL         = aws_glue_connection.this.connection_properties.JDBC_CONNECTION_URL
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.web.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_gluecatalog.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "s3-trigger-permission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_gluecatalog.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.web.arn
}
