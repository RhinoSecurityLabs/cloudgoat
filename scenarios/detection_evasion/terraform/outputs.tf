#IAM User Credentials
output "cloudgoat_output_r_waterhouse_access_key_id" {
  value = aws_iam_access_key.r_waterhouse.id
}
output "cloudgoat_output_r_waterhouse_secret_key" {
  value = aws_iam_access_key.r_waterhouse.secret
  sensitive = true
}
output "cloudgoat_output_c_english_access_key_id" {
  value = aws_iam_access_key.c_english.id
}
output "cloudgoat_output_c_english_secret_key" {
  value = aws_iam_access_key.c_english.secret
  sensitive = true
}
output "cloudgoat_output_l_salander_access_key_id" {
  value = aws_iam_access_key.l_salander.id
}
output "cloudgoat_output_l_salander_secret_key" {
  value = aws_iam_access_key.l_salander.secret
  sensitive = true
}
output "cloudgoat_output_s_cylander_access_key_id" {
  value = aws_iam_access_key.s_cylander.id
}
output "cloudgoat_output_s_cylander_secret_key" {
  value = aws_iam_access_key.s_cylander.secret
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
  value = "This will be the location that alerts are sent if you are detected."
}
#Scenario note
output "Start_Note" {
  value = "You are given 4 pairs of credentials to start this scenario. Surely some of them are traps..."
}