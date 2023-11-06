
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
    Stack       = "${var.stack-name}"
    Scenario    = "${var.scenario-name}"
  }
}


resource "aws_s3_bucket_acl" "cg-data-s3-bucket-acl" {
  bucket = aws_s3_bucket.cg-data-s3-bucket.id
  acl    = "private"
}

# # S3 Bucket에 넣을 파일
# resource "aws_s3_object" "cg-mistake-credentials" {
#   bucket = "${aws_s3_bucket.cg-data-s3-bucket.id}"
#   key = "test.csv"
#   source = "../assets/test.csv"
#   tags = {
#     Name = "cg-shepards-credentials-${var.cgid}"
#     Stack = "${var.stack-name}"
#     Scenario = "${var.scenario-name}"
#   }
# }


# web to s3
# test-glue-scenario2
resource "aws_s3_bucket" "cg-data-from-web" {
  bucket        = "cg-data-from-web-${local.bucket_suffix}"
  force_destroy = true
  tags = {
    Name        = "cg-data-from-web-${local.bucket_suffix}"
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a Data"
    Stack       = "${var.stack-name}"
    Scenario    = "${var.scenario-name}"
  }
}


resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.cg-data-from-web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "putobject" {
  bucket = aws_s3_bucket.cg-data-from-web.id
  policy = jsondecode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.cg-data-from-web.arn}/*"
      }
    ]
  })
}