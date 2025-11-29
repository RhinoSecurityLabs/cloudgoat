resource "aws_s3_bucket" "kb_s3_bucket" {
  bucket = "cg-knowldegebase-bucket-${replace(var.cgid, "/[^a-z0-9-.]/", "-")}"
}

resource "aws_s3_object" "example_file" {
  bucket       = aws_s3_bucket.kb_s3_bucket.bucket
  key          = "flag.txt"
  content      = "FLAG{ar3_y0u_@n_ag3nt?}"
  content_type = "text/plain"
}

# False flag
resource "aws_s3_bucket" "kb_code_interpreter_bucket" {
  bucket = "cg-codeinterpreter-artifacts-${replace(var.cgid, "/[^a-z0-9-.]/", "-")}"
}

resource "aws_s3_object" "decoy_file" {
  bucket       = aws_s3_bucket.kb_code_interpreter_bucket.bucket
  key          = "flag.txt"
  content      = "Your flag is in another location..."
  content_type = "text/plain"
}