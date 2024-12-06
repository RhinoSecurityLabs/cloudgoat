#IAM User Credentials
output "manager_access_key_id" {
  value = aws_iam_access_key.manager.id
}

output "manager_secret_key" {
  value     = aws_iam_access_key.manager.secret
  sensitive = true
}

output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}
