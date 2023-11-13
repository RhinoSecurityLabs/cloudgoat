data "archive_file" "cg-lambda-function" {
  type = "zip"
  source_file = "../assets/s3_to_gluecatalog.py"
  output_path = "../assets/s3_to_gluecatalog.zip"
}

resource "aws_lambda_function" "s3_to_gluecatalog" {
  function_name = "s3_to_gluecatalog"
  handler       = "lambda_handler"
  role          = aws_iam_role.s3_to_gluecatalog_lambda_role.arn
  runtime       = "python3.11"

  filename         = "../assets/s3_to_gluecatalog.zip"
  source_code_hash = filebase64sha256("../assets/s3_to_gluecatalog.py")

  timeout = 300
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.cg-data-from-web.id

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.s3_to_gluecatalog.arn}"
    events              = ["s3:ObjectCreated:Put"]
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3_to_gluecatalog.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.cg-data-from-web.arn}/*"
}