## This outputs the starting keys/info for the scenario 
output "cg-user1-access_key" {
  description = "The access key for cg-user1"
  value       = aws_iam_access_key.cg-user1-key.id
}

output "cg-user1-secret_key" {
  description = "The secret key for cg-user1"
  value       = aws_iam_access_key.cg-user1-key.secret
  sensitive   = true
}

output "cg-user2-access_key" {
  description = "The access key for cg-user2"
  value       = aws_iam_access_key.cg-user2-key.id
}

output "cg-user2-secret_key" {
  description = "The secret key for cg-user2"
  value       = aws_iam_access_key.cg-user2-key.secret
  sensitive   = true
}
