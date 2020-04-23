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

output "cloudgoat_output_policy_arn" {
  value = "${aws_iam_policy.cg-raynor-policy.arn}"
}

output "cloudgoat_output_username" {
  value = "${aws_iam_user.cg-raynor.name}"
}
