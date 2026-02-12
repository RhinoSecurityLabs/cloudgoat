resource "aws_s3_bucket" "flag_bucket" {
  bucket = "cg-s3-version-flag-${var.cgid}"
  tags = {
    Purpose = "Flag Only"
  }
}

resource "aws_s3_bucket_public_access_block" "flag_block" {
  bucket = aws_s3_bucket.flag_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "flag_txt" {
  bucket       = aws_s3_bucket.flag_bucket.id
  key          = "flag.txt"
  content      = "Flag{version_bypass_s3_only}"
  content_type = "text/plain"

  depends_on = [
    aws_s3_bucket.flag_bucket,
    aws_s3_bucket_public_access_block.flag_block
  ]
}

resource "aws_s3_bucket_policy" "flag_bucket_policy" {
  bucket = aws_s3_bucket.flag_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.flag_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowOnlyFromReferer",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.flag_bucket.arn}/flag.txt",
        Condition: {
          StringLike: {
            "aws:Referer": "http://${aws_s3_bucket.index_bucket.bucket}.s3-website-${var.region}.amazonaws.com/*"
          }
        }
      },
      {
        Sid: "DenyWithoutReferer",
        Effect: "Deny",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.flag_bucket.arn}/flag.txt",
        Condition: {
          Null: {
            "aws:Referer": "true"
          }
        }
      },
      {
        Sid: "DenyFromIAMUsers",
        Effect: "Deny",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.flag_bucket.arn}/flag.txt",
        Condition: {
          StringLike: {
            "aws:PrincipalArn": "arn:aws:iam::*:user/*"
          }
        }
      },
      {
        Sid: "DenyFromAssumedRoles",
        Effect: "Deny",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.flag_bucket.arn}/flag.txt",
        Condition: {
          StringEquals: {
            "aws:PrincipalType": "AssumedRole"
          }
        }
      },
      {
        Sid: "DenyFromAuthenticatedUsers",
        Effect: "Deny",
        Principal: {
          AWS: "*"
        },
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.flag_bucket.arn}/flag.txt",
        Condition: {
          Bool: {
            "aws:PrincipalIsAWSService": "false"
          },
          StringNotEquals: {
            "aws:userid": "anonymous"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "flag_cors" {
  bucket = aws_s3_bucket.flag_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["http://${aws_s3_bucket.index_bucket.bucket}.s3-website-${var.region}.amazonaws.com"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "index_bucket" {
  bucket = "cg-s3-version-index-${var.cgid}"
  object_lock_enabled = true
  tags = {
    Purpose = "Public Index"
  }
}

resource "aws_s3_bucket_public_access_block" "index_block" {
  bucket = aws_s3_bucket.index_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "index_website" {
  bucket = aws_s3_bucket.index_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.index_bucket.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }

  depends_on = [aws_s3_bucket.index_bucket]
}

resource "aws_s3_bucket_policy" "index_bucket_policy" {
  bucket = aws_s3_bucket.index_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.index_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "PublicReadForIndex",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.index_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index_admin" {
  bucket       = aws_s3_bucket.index_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOT
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>S3 Flag Viewer</title></head>
<body style="background:#111;color:#0f0;text-align:center;padding-top:100px;font-family:monospace">
  <h1>🔓 S3 Flag Viewer</h1>
  <div id="flag">Loading flag...</div>
  <script>
    fetch("https://${aws_s3_bucket.flag_bucket.bucket}.s3.amazonaws.com/flag.txt")
    .then(r => r.text()).then(t => {
      document.getElementById("flag").innerHTML = "✅ FLAG: " + t;
    }).catch(e => {
      document.getElementById("flag").innerHTML = "❌ Failed to load flag";
    });
  </script>
</body>
</html>
EOT

  depends_on = [aws_s3_bucket_versioning.versioning]
}

resource "aws_s3_object" "index_normal" {
  bucket       = aws_s3_bucket.index_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = "<h1>Welcome to our site</h1>"

  object_lock_mode               = "GOVERNANCE"
  object_lock_retain_until_date = "2099-12-31T00:00:00Z"

  depends_on = [
    aws_s3_object.index_admin,
    aws_s3_bucket_versioning.versioning
  ]
}