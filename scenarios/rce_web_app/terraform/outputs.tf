#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}
#IAM User Credentials
output "cloudgoat_output_lara_access_key_id" {
  value = "${aws_iam_access_key.cg-lara.id}"
}
output "cloudgoat_output_lara_secret_key" {
  value = "${aws_iam_access_key.cg-lara.secret}"
}
output "cloudgoat_output_mcduck_access_key_id" {
  value = "${aws_iam_access_key.cg-mcduck.id}"
}
output "cloudgoat_output_mcduck_secret_key" {
  value = "${aws_iam_access_key.cg-mcduck.secret}"
}