output "cloudgoat_output_kerrigan_access_key_id" {
  value = aws_iam_access_key.kerrigan.id
}

output "cloudgoat_output_kerrigan_secret_key" {
  value     = aws_iam_access_key.kerrigan.secret
  sensitive = true
}

output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.aws_account_id.account_id
}
