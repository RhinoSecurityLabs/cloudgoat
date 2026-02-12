output "start_user_access_key" {
  description = "The access key for the starting user"
  value       = aws_iam_access_key.start_user.id
}

output "start_user_secret_key" {
  description = "The secret key for the starting user"
  value       = aws_iam_access_key.start_user.secret
  sensitive   = true
}