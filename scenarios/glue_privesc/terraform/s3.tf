/*

This creates AWS S3 Buckets, S3 Objects, and S3 Policies.

*/

# Bucket Name Suffix
locals {
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}

#S3 Bucket glue-final
resource "aws_s3_bucket" "cg-data-s3-bucket" {
  bucket        = "cg-data-s3-bucket-${local.bucket_suffix}"
  force_destroy = true
  tags = {
    Name        = "cg-data-s3-bucket-${local.bucket_suffix}"
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a Data"
    Stack       = var.stack-name
    Scenario    = var.scenario-name
  }
}


resource "aws_s3_bucket_acl" "cg-data-s3-bucket-acl" {
  bucket     = aws_s3_bucket.cg-data-s3-bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.cg-data-s3-bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# web to s3
# test-glue-scenario2
resource "aws_s3_bucket" "cg-data-from-web" {
  bucket        = "cg-data-from-web-${local.bucket_suffix}"
  force_destroy = true
  tags = {
    Name        = "cg-data-from-web-${local.bucket_suffix}"
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a Data"
    Stack       = var.stack-name
    Scenario    = var.scenario-name
  }
}

resource "aws_s3_object" "web-data-primary" {
  bucket = aws_s3_bucket.cg-data-from-web.id
  key    = "order_data2.csv"
  source = "${path.module}/../assets/order_data2.csv"
  tags = {
    Name     = "web-data-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}


resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.cg-data-from-web.id

  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = false
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "put_object" {
  bucket = aws_s3_bucket.cg-data-from-web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Statement1"
        Action    = ["s3:PutObject"]
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.cg-data-from-web.arn}/*"
        Principal = "*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.access_block]
}
