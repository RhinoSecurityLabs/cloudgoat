locals {
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}


resource "aws_s3_bucket" "data" {
  bucket        = "cg-data-${local.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "data_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.data_ownership
  ]

  bucket = aws_s3_bucket.data.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "data_ownership" {
  bucket = aws_s3_bucket.data.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_object" "glue_script_file" {
  bucket = aws_s3_bucket.data.id
  key    = "ETL_JOB.py"
  source = "source/ETL_JOB.py"
}


resource "aws_s3_bucket" "web" {
  bucket        = "cg-web-${local.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_object" "primary_web_data" {
  bucket = aws_s3_bucket.web.id
  key    = "order_data2.csv"
  source = "source/order_data.csv"
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.web.id

  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "put_object" {
  depends_on = [
    aws_s3_bucket_public_access_block.access_block
  ]

  bucket = aws_s3_bucket.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:PutObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.web.arn}/*"
        Principal = "*"
      }
    ]
  })
}
