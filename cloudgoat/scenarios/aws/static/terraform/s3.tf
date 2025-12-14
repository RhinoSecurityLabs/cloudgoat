# s3.tf

resource "aws_s3_bucket" "assets_bucket" {
  bucket        = "cg-assets-${var.cgid}"
  force_destroy = true 

  tags = {
    Name     = "cg-assets-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

# 1. DISABLE S3 Public Access Block 
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
  depends_on = [aws_s3_bucket_public_access_block.assets_bucket_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadWrite"
        Effect    = "Allow"
        Principal = "*" 
        Action    = [
          "s3:GetObject",  # Allows website to load the image
          "s3:ListBucket", # Allows attacker to find the file
          "s3:PutObject"   # <--- THE VULNERABILITY (Allows defacement)
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

# 3. THE "IMAGE" (SVG)
# We create a simple green shield logo using code so we don't need a binary file.
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