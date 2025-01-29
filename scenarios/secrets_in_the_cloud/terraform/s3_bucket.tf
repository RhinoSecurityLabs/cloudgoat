# This Terraform file creates the following AWS Simple Storage Service Resources:
# - An AWS S3 Bucket 
# - An AWS S3 Object

resource "aws_s3_bucket" "secrets_bucket" {
  bucket        = "cg-secrets-bucket-${local.cgid_suffix}"
  force_destroy = true
  tags = {
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing seekz."
  }
}

resource "aws_s3_object" "web_app_url" {
  bucket  = aws_s3_bucket.secrets_bucket.id
  key     = "nates_web_app_url.txt"
  content = "http://${aws_instance.web_app.public_ip}:8080"
}
