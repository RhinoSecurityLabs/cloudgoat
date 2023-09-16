locals {
  suffix = replace(var.cgid, "/[^a-z0-9]/", "")
}


resource "aws_s3_bucket" "cognito_s3" {
  bucket = "cognitoctf-${local.suffix}"
  force_destroy = true
}



resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.cognito_s3.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}


data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:Get*",
    ]

    resources = [
      aws_s3_bucket.cognito_s3.arn,
      "${aws_s3_bucket.cognito_s3.arn}/*",
    ]
  }
}

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

resource "aws_s3_bucket_object" "dist" {
  for_each = fileset("../assets/app/static/", "*")

  bucket = aws_s3_bucket.cognito_s3.id
  key    = each.value
  source = "../assets/app/static/${each.value}"
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  etag   = filemd5("../assets/app/static/${each.value}")
}



resource "aws_s3_bucket_object" "html" {
  for_each = fileset("../assets/app/", "*")

  bucket = aws_s3_bucket.cognito_s3.id
  key    = each.value
  #source = "../assets/app/${each.value}"
  content  = data.template_file.data[each.value].rendered
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  etag   = filemd5("../assets/app/${each.value}")
}


data "template_file" "data" {
  for_each = fileset("../assets/app", "*")
  template = file("../assets/app/${each.value}")

  vars = {
    cognito_userpool_id = aws_cognito_user_pool.ctf_pool.id
    cognito_userpool_uri = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.ctf_pool.id}"
    cognito_identity_id = aws_cognito_identity_pool.main.id
    cognito_client_id = aws_cognito_user_pool_client.cognito_client.id
    region_html = var.region
  }

}



