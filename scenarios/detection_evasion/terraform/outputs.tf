#IAM User Credentials
output "user4_access_key_id" {
  value = aws_iam_access_key.r_waterhouse.id
}
output "user4_secret_key" {
  value     = aws_iam_access_key.r_waterhouse.secret
  sensitive = true
}
output "user1_access_key_id" {
  value = aws_iam_access_key.canarytoken_user.id
}
output "user1_secret_key" {
  value     = aws_iam_access_key.canarytoken_user.secret
  sensitive = true
}
output "user2_access_key_id" {
  value = aws_iam_access_key.spacecrab_user.id
}
output "user2_secret_key" {
  value     = aws_iam_access_key.spacecrab_user.secret
  sensitive = true
}
output "user3_access_key_id" {
  value = aws_iam_access_key.spacesiren_user.id
}
output "user3_secret_key" {
  value     = aws_iam_access_key.spacesiren_user.secret
  sensitive = true
}
#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.aws-account-id.account_id
}
output "scenario_cg_id" {
  value = var.cgid
}
#Alert Location
output "Alert_Location" {
  value = var.user_email
}
#Scenario note
output "Start_Note" {
  value = "You are given 4 pairs of credentials to start this scenario. Surely some of them are traps..."
}