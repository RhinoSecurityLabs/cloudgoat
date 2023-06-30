#Secret S3 Bucket
locals {
  # Ensure the bucket suffix doesn't contain invalid characters
  # "Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  # (per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) 
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}

resource "aws_s3_bucket" "cg-secret-s3-bucket" {
  bucket = "cg-secret-s3-bucket-${local.bucket_suffix}"
  force_destroy = true
  tags = {
      Name = "cg-secret-s3-bucket-${local.bucket_suffix}"
      Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a secret"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}

resource "aws_s3_object" "cg-shepards-credentials" {
  bucket = "${aws_s3_bucket.cg-secret-s3-bucket.id}"
  key = "admin-user.txt"
  source = "../assets/admin-user.txt"
  tags = {
    Name = "cg-shepards-credentials-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
