resource "aws_s3_bucket" "versioned_bucket" {
  bucket              = "cg-s3-version-bypass-${var.cgid}"
  object_lock_enabled = true

  tags = {
    Scenario = var.scenario_name
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.versioned_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.versioned_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "flag_file" {
  bucket       = aws_s3_bucket.versioned_bucket.id
  key          = "flag.txt"
  content      = "Flag{version_bypass_s3_only}"
  content_type = "text/plain"

  depends_on = [aws_s3_bucket_versioning.versioning]
}


resource "aws_s3_bucket_policy" "public_read_with_flag_deny" {
  bucket = aws_s3_bucket.versioned_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.versioned_bucket.arn}/*"
      },
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.versioned_bucket.arn}/flag.txt",
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::*:user/*"
            ]
          }
        }
      },
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.versioned_bucket.arn}/flag.txt",
        Condition = {
          StringEquals = {
            "aws:PrincipalType" = "AssumedRole"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_object.flag_file,
    aws_s3_bucket_public_access_block.public_access
  ]
}


resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.versioned_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.versioned_bucket.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }

  depends_on = [aws_s3_bucket.versioned_bucket]
}

resource "aws_s3_object" "index_admin" {
  bucket       = aws_s3_bucket.versioned_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOT
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>S3 Version Flag</title>
  <style>
    body {
      font-family: monospace;
      background: #111;
      color: #0f0;
      text-align: center;
      padding-top: 100px;
    }
  </style>
</head>
<body>
  <h1>🔓 S3 Flag Viewer</h1>
  <div id="flag">Loading flag...</div>

  <script>
    fetch("flag.txt")
      .then(res => res.text())
      .then(flag => {
        document.getElementById("flag").innerHTML = "✅ FLAG: " + flag;
      })
      .catch(err => {
        document.getElementById("flag").innerHTML = "❌ Failed to load flag: " + err;
      });
  </script>
</body>
</html>
EOT

  depends_on = [aws_s3_bucket_versioning.versioning]
}

resource "aws_s3_object" "index_normal" {
  bucket       = aws_s3_bucket.versioned_bucket.id
  key          = "index.html"
  content      = "<h1>Welcome to our site</h1>"
  content_type = "text/html"

  object_lock_mode               = "GOVERNANCE"
  object_lock_retain_until_date = "2099-12-31T00:00:00Z"

  depends_on = [
    aws_s3_object.index_admin,
    aws_s3_bucket_versioning.versioning
  ]
}