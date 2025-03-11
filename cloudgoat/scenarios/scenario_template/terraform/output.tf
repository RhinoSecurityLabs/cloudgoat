## This outputs the starting keys/info for the scenario 
output "user1_access_key" {
  description = "The access key for user1"
  value       = aws_iam_access_key.user1.id
}

output "user1_secret_key" {
  description = "The secret key for user1"
  value       = aws_iam_access_key.user1.secret
  sensitive   = true
}


output "user2_access_key" {
  description = "The access key for user2"
  value       = aws_iam_access_key.user2.id
}

output "user2_secret_key" {
  description = "The secret key for user2"
  value       = aws_iam_access_key.user2.secret
  sensitive   = true
}
