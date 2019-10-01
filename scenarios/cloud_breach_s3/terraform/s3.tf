#Secret S3 Bucket
resource "aws_s3_bucket" "cg-cardholder-data-bucket" {
  bucket = "cg-cardholder-data-bucket-${var.cgid}"
  acl = "private"
  force_destroy = true
  tags = {
      Name = "cg-cardholder-data-bucket-${var.cgid}"
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