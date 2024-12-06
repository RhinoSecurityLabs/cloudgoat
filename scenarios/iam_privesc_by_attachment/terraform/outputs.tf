output "cloudgoat_output_kerrigan_access_key_id" {
  description = "AWS access key id for Kerrigan"
  value       = aws_iam_access_key.kerrigan.id
}

output "cloudgoat_output_kerrigan_secret_key" {
  description = "AWS secret access key for Kerrigan"
  value       = aws_iam_access_key.kerrigan.secret
  sensitive   = true
}

output "cloudgoat_output_aws_account_id" {
  description = "AWS account id"
  value       = data.aws_caller_identity.aws_account_id.account_id
}
