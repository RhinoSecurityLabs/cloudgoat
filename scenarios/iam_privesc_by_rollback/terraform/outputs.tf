#IAM User Credentials
output "cloudgoat_output_raynor_access_key_id" {
  value = "${aws_iam_access_key.cg-raynor.id}"
}
output "cloudgoat_output_raynor_secret_key" {
  value = "${aws_iam_access_key.cg-raynor.secret}"
}
#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}