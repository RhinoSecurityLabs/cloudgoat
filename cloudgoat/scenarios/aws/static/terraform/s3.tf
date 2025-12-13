# s3.tf

resource "aws_s3_bucket" "assets_bucket" {
  bucket        = "cg-assets-${var.cgid}"
  force_destroy = true # Allows deleting bucket even if user uploaded files

  tags = {
    Name     = "cg-assets-${var.cgid}"
    Stack    = var.stack_name
    Scenario = var.scenario_name
  }
}

# 1. DISABLE S3 Public Access Block 
# (By default, AWS blocks all public access. We must turn this off to be vulnerable.)
resource "aws_s3_bucket_public_access_block" "assets_bucket_access" {
  bucket = aws_s3_bucket.assets_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 2. THE VULNERABLE POLICY
resource "aws_s3_bucket_policy" "assets_bucket_policy" {
  bucket = aws_s3_bucket.assets_bucket.id

  # We depend on the public access block being removed first
  depends_on = [aws_s3_bucket_public_access_block.assets_bucket_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Legitimate Access (The Web Server)
      {
        Sid       = "AllowWebServerAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_role.arn
        }
        Action    = ["s3:GetObject", "s3:ListBucket"]
        Resource  = [
          aws_s3_bucket.assets_bucket.arn,
          "${aws_s3_bucket.assets_bucket.arn}/*"
        ]
      },
      # THE VULNERABILITY: "Public" Write Access
      # In a real hack, Principal would be "*" and there would be no Condition.
      # For CloudGoat safety, we restrict "*" to your Whitelisted IP only.
      {
        Sid       = "PublicWriteAccess"
        Effect    = "Allow"
        Principal = "*" 
        Action    = [
          "s3:ListBucket", # Lets them enumerate files
          "s3:GetObject",  # Lets them read files
          "s3:PutObject"   # <--- THE DEFACE VULN
        ]
        Resource  = [
          aws_s3_bucket.assets_bucket.arn,
          "${aws_s3_bucket.assets_bucket.arn}/*"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.cg_whitelist
          }
        }
      }
    ]
  })
}

# Optional: Upload a legitimate looking file so the bucket isn't empty
resource "aws_s3_object" "logo" {
  bucket = aws_s3_bucket.assets_bucket.id
  key    = "hacksmarter_logo.png"
  source = "/dev/null" # Just a dummy empty file for demonstration
  content_type = "image/png"
}