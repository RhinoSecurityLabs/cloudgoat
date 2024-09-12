output "sns_user_access_key_id" {
  value = aws_iam_access_key.sns_user_key.id
}

output "sns_user_secret_access_key" {
  value     = aws_iam_access_key.sns_user_key.secret
  sensitive = true
}
