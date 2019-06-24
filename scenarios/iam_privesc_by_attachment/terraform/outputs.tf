#IAM User Credentials
output "cloudgoat_output_kerrigan_access_key_id" {
  value = "${aws_iam_access_key.cg-kerrigan.id}"
}
output "cloudgoat_output_kerrigan_secret_key" {
  value = "${aws_iam_access_key.cg-kerrigan.secret}"
}
#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}