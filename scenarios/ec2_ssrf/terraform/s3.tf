#Secret S3 Bucket
resource "aws_s3_bucket" "cg-secret-s3-bucket" {
  bucket = "cg-secret-s3-bucket-${var.cgid}"
  acl = "private"
  force_destroy = true
  tags = {
      Name = "cg-secret-s3-bucket-${var.cgid}"
      Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a secret"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cg-shepards-credentials" {
  bucket = "${aws_s3_bucket.cg-secret-s3-bucket.id}"
  key = "admin-user.txt"
  source = "../assets/admin-user.txt"
  tags = {
    Name = "cg-shepards-credentials-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}