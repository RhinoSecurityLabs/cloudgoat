locals {
  mime_types = {
    "css"  = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "png"  = "image/png"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
  }
}


resource "aws_s3_bucket" "cognito_s3" {
  bucket        = "cognitoctf-${replace(var.cgid, "/[^a-z0-9]/", "")}"
  force_destroy = true
}

# AWS will block the bucket policy unless access is granted
resource "aws_s3_bucket_public_access_block" "cognito_s3" {
  bucket = aws_s3_bucket.cognito_s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  depends_on = [aws_s3_bucket_public_access_block.cognito_s3]

  bucket = aws_s3_bucket.cognito_s3.id
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = ""
          Effect = "Allow"
          Principal = {
            AWS = "*"
          },
          Action = "s3:Get*"
          Resource = [
            "${aws_s3_bucket.cognito_s3.arn}/*",
            aws_s3_bucket.cognito_s3.arn
          ]
        }
      ]
    }
  )
}

resource "aws_s3_object" "dist" {
  for_each = fileset("../assets/app/static/", "*")

  bucket       = aws_s3_bucket.cognito_s3.id
  key          = each.value
  source       = "../assets/app/static/${each.value}"
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  source_hash  = filemd5("../assets/app/static/${each.value}")
}

resource "aws_s3_object" "html" {
  for_each = fileset("../assets/app/", "*")

  bucket       = aws_s3_bucket.cognito_s3.id
  key          = each.value
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  source_hash  = filemd5("../assets/app/${each.value}")

  content = templatefile("../assets/app/${each.value}", {
    cognito_userpool_id  = aws_cognito_user_pool.ctf_pool.id
    cognito_userpool_uri = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.ctf_pool.id}"
    cognito_identity_id  = aws_cognito_identity_pool.main.id
    cognito_client_id    = aws_cognito_user_pool_client.cognito_client.id
    region_html          = var.region
  })
}
