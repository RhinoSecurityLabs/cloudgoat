output "cloudgoat_output_lara_access_key_id" {
  value = aws_iam_access_key.lara.id
}

output "cloudgoat_output_lara_secret_key" {
  value     = aws_iam_access_key.lara.secret
  sensitive = true
}


output "cloudgoat_output_mcduck_access_key_id" {
  value = aws_iam_access_key.mcduck.id
}

output "cloudgoat_output_mcduck_secret_key" {
  value     = aws_iam_access_key.mcduck.secret
  sensitive = true
}
