output "manager_access_key_id" {
  description = "Manager Access Key ID"
  value       = aws_iam_access_key.manager.id
}

output "manager_secret_access_key" {
  description = "Manager Secret Access Key"
  value       = aws_iam_access_key.manager.secret
  sensitive   = true

}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
