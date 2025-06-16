# cg_dev_user access keys
output "dev_user_access_key_id" {
  value = aws_iam_access_key.dev_user_key.id
}

output "dev_user_secret_access_key" {
  value     = aws_iam_access_key.dev_user_key.secret
  sensitive = true
}
