#Secret S3 Bucket
locals {
  # Ensure the bucket suffix doesn't contain invalid characters
  # "Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  # (per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
  bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}

# Create Secret Bucket
resource "aws_s3_bucket" "secret-s3-bucket" {
  bucket        = "cg-s3-${local.bucket_suffix}"
  force_destroy = true
}

# Store secret string for easy path in flag.txt
resource "aws_s3_object" "credentials_easy_path" {
  bucket = aws_s3_bucket.secret-s3-bucket.id
  key    = "flag.txt"
  source = "./flag.txt"
}

# Store secret string for hard path in critical.txt
resource "aws_s3_object" "credentials_hard_path" {
  bucket = aws_s3_bucket.secret-s3-bucket.id
  key    = "secret-string.txt"
  source = "./secret-string.txt"
}

# AWS CLI logs for GuardDuty analysis
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "cg-cloudtrail-s3-${local.bucket_suffix}"
  force_destroy = true
}

# Block public access for Cloudtrail Logs Bucket
resource "aws_s3_bucket_public_access_block" "trail_bucket_block_public" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
      },{
        Effect = "Allow",
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },{
        Effect = "Allow",
        Action = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.cloudtrail_bucket.arn,
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}