output "access_key_id" {
  value     = aws_iam_access_key.web_manager_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.web_manager_key.secret
  sensitive = true
}

output "website_url" {
  value       = "http://${aws_s3_bucket.versioned_bucket.bucket}.s3-website-${data.aws_region.current.id}.amazonaws.com"
  description = "URL of the static website"
}