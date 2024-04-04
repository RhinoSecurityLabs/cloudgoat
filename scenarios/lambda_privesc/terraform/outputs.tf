output "cloudgoat_output_chris_access_key_id" {
  value = aws_iam_access_key.chris.id
}
output "cloudgoat_output_chris_secret_key" {
  value     = aws_iam_access_key.chris.secret
  sensitive = true
}
