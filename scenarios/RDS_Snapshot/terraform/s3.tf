locals {
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}

resource "aws_s3_bucket" "cg-data-s3-bucket" {
  bucket        = "cg-data-s3-bucket-${local.bucket_suffix}"
  force_destroy = true
  acl    = "private"
  tags = {
    Name        = "cg-data-s3-bucket-${local.bucket_suffix}"
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a Data"
  }
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.cg-data-s3-bucket.id
  key    = "access_keys.txt"
  content = "Access Key: ${aws_iam_access_key.cg-rds_instance.id}, Secret Key: ${aws_iam_access_key.cg-rds_instance.secret}"
}
