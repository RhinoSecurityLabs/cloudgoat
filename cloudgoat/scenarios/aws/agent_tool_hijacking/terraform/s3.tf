resource "aws_s3_bucket" "target_s3_bucket" {
  bucket = "cg-bedrock-secret-flag-${replace(var.cgid, "/[^a-z0-9-.]/", "-")}"
}

resource "aws_s3_object" "example_file" {
  bucket       = aws_s3_bucket.target_s3_bucket.bucket
  key          = "flag.txt"
  content      = "FLAG{@g3nt5_h@v3_p3rm1ss10ns}"
  content_type = "text/plain"
}
