# This Terraform file creates output values to expose information 
# about the infrastructure:
# - A Low-Privilege Access Key
# - A Low-Privilege Secret Key

output "low_priv_access_key" {
  value       = aws_iam_access_key.low_priv_user_key.id
  description = "Access key ID for the low privilege IAM user."
}

output "low_priv_secret_key" {
  value       = aws_iam_access_key.low_priv_user_key.secret
  description = "Secret access key for the low privilege IAM user."
  sensitive   = true
}
