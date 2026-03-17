output "cloudgoat_output_bob_access_key" {
  description = "The access key for our starting user, Bob."
  value       = aws_iam_access_key.bob_keys.id
}

output "cloudgoat_output_bob_secret_key" {
  description = "The secret key for our starting user, Bob."
  value       = aws_iam_access_key.bob_keys.secret
  sensitive   = true
}