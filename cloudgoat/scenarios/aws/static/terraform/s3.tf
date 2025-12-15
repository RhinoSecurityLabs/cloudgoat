# s3.tf

resource "aws_s3_bucket" "assets_bucket" {
  bucket        = "cg-assets-${var.cgid}"
  force_destroy = true 

  tags = {
    Name     = "cg-assets-${var.cgid}"
    Stack    = var.stack_name
    Scenario = var.scenario_name
  }
}

# 1. ENABLE CORS (Required for JS fetch PUT)
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.assets_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "assets_bucket_access" {
  bucket = aws_s3_bucket.assets_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 2. POLICY: Allow User IP AND Bot IP
resource "aws_s3_bucket_policy" "assets_bucket_policy" {
  bucket = aws_s3_bucket.assets_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.assets_bucket_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadWrite"
        Effect    = "Allow"
        Principal = "*" 
        Action    = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource  = [
          aws_s3_bucket.assets_bucket.arn,
          "${aws_s3_bucket.assets_bucket.arn}/*"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp" = concat(var.cg_whitelist, ["${aws_eip.web_ip.public_ip}/32"])
          }
        }
      }
    ]
  })
}

# 3. INITIAL ASSETS

resource "aws_s3_object" "logo" {
  bucket       = aws_s3_bucket.assets_bucket.id
  key          = "logo.svg"
  content_type = "image/svg+xml"
  content      = <<EOF
<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <polygon points="50,10 90,30 90,70 50,90 10,70 10,30" fill="#0d0d0d" stroke="#00ff41" stroke-width="4"/>
  <text x="50" y="60" font-family="Arial" font-size="40" fill="#00ff41" text-anchor="middle">H</text>
</svg>
EOF
}

# The benign JS file
resource "aws_s3_object" "script" {
  bucket       = aws_s3_bucket.assets_bucket.id
  key          = "auth-module.js"
  content_type = "application/javascript"
  content      = "console.log('Hacksmarter Auth Module v1.2 loaded.');" 
}