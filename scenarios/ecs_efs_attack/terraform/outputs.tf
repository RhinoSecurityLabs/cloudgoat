
#Required: Always output the AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}
output "cloudgoat_output_solus_access_key_id" {
  value = "${aws_iam_access_key.cg-solus.id}"
}
output "cloudgoat_output_solus_secret_key" {
  value = "${aws_iam_access_key.cg-solus.secret}"
}