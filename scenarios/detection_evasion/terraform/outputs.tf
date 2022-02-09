#IAM User Credentials
output "cloudgoat_output_r_waterhouse_access_key_id" {
  value = aws_iam_access_key.r_waterhouse.id
}
output "cloudgoat_output_r_waterhouse_secret_key" {
  value = aws_iam_access_key.r_waterhouse.secret
  sensitive = true
}

#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.aws-account-id.account_id
}
output "scenario_cg_id" {
  value = var.cgid
}