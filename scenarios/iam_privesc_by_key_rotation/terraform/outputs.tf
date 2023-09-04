#IAM User Credentials
output "cloudgoat_output_kerrigan_access_key_id" {
  value = aws_iam_access_key.devops.id
}

output "cloudgoat_output_kerrigan_secret_key" {
  value     = aws_iam_access_key.devops.secret
  sensitive = true
}

output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}
