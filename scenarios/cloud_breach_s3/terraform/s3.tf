#Secret S3 Bucket
locals {
  # Ensure the bucket suffix doesn't contain invalid characters
  # "Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  # (per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) 
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}

resource "aws_s3_bucket" "cg-cardholder-data-bucket" {
  bucket = "cg-cardholder-data-bucket-${local.bucket_suffix}"
  force_destroy = true
  tags = {
      Name = "cg-cardholder-data-bucket-${local.bucket_suffix}"
      Description = "CloudGoat ${var.cgid} S3 Bucket used for storing sensitive cardholder data."
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cardholder-data-primary" {
  bucket = "${aws_s3_bucket.cg-cardholder-data-bucket.id}"
  key = "cardholder_data_primary.csv"
  source = "../assets/cardholder_data_primary.csv"
  tags = {
    Name = "cardholder-data-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cardholder-data-secondary" {
  bucket = "${aws_s3_bucket.cg-cardholder-data-bucket.id}"
  key = "cardholder_data_secondary.csv"
  source = "../assets/cardholder_data_secondary.csv"
  tags = {
    Name = "cardholder-data-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cardholder-data-corporate" {
  bucket = "${aws_s3_bucket.cg-cardholder-data-bucket.id}"
  key = "cardholders_corporate.csv"
  source = "../assets/cardholders_corporate.csv"
  tags = {
    Name = "cardholder-data-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "goat" {
  bucket = "${aws_s3_bucket.cg-cardholder-data-bucket.id}"
  key = "goat.png"
  source = "../assets/goat.png"
  tags = {
    Name = "cardholder-data-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_s3_bucket_acl" "cardholder-data-bucket-acl" {
  bucket = aws_s3_bucket.cg-cardholder-data-bucket.id
  acl    = "private"
}