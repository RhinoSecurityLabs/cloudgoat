output "cg_sns_user_access_key_id" {
  value = aws_iam_access_key.cg-sns-user-key.id
}

output "cg_sns_user_secret_access_key" {
  value     = aws_iam_access_key.cg-sns-user-key.secret
  sensitive = true
}
