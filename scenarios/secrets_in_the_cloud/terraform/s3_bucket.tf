# This Terraform file creates the following AWS Simple Storage Service Resources:
# - A bucket suffix variable
# - A web application URL variable
# - An AWS S3 Bucket 
# - An AWS S3 Object

locals {
  # Ensure the bucket suffix doesn't contain invalid characters
  # "Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  # (per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) 
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}

locals {
  web_app_url = "http://${aws_instance.web_app.public_ip}:8080"
}

resource "aws_s3_bucket" "cg-secrets-bucket" {
  bucket = "cg-secrets-bucket-${local.bucket_suffix}"
  force_destroy = true
  tags = {
      Name = "cg-secrets-bucket-${local.bucket_suffix}"
      Description = "CloudGoat ${var.cgid} S3 Bucket used for storing seekz."
  }
}

resource "aws_s3_object" "web_app_url" {
  bucket = "${aws_s3_bucket.cg-secrets-bucket.id}"
  key = "nates_web_app_url.txt"
  content = "${local.web_app_url}"
  tags = {
    Name = "secrets-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
