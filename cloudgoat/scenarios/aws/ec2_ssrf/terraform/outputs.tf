output "cloudgoat_output_solus_access_key_id" {
  value = aws_iam_access_key.solus.id
}

output "cloudgoat_output_solus_secret_key" {
  value     = aws_iam_access_key.solus.secret
  sensitive = true
}
