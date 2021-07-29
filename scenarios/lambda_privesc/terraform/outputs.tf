#IAM User Credentials
output "cloudgoat_output_chris_access_key_id" {
  value = aws_iam_access_key.cg-chris.id
}
output "cloudgoat_output_chris_secret_key" {
  value = aws_iam_access_key.cg-chris.secret
  sensitive = true
}
#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.aws-account-id.account_id
}

output "definition_of_done" {
  value = <<EOT
  This lab is considered done once you can run 'aws iam list-attached-user-policies' on your user and it 
  is confirmed to have the 'AdministratorAccess' policy.
  EOT
}