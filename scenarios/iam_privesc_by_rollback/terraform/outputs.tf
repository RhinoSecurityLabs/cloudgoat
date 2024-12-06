output "raynor_access_key_id" {
  description = "The access key ID for the Raynor user"
  value       = aws_iam_access_key.raynor.id
}

output "raynor_secret_access_key" {
  description = "The secret access key for the Raynor user"
  value       = aws_iam_access_key.raynor.secret
  sensitive   = true
}
