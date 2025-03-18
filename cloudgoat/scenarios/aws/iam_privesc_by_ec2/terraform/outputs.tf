# cg_dev_user access keys
output "cg_dev_user_access_key_id" {
  value = "${aws_iam_access_key.cg_dev_user_key.id}"
}

output "cg_dev_user_secret_access_key" {
  value = "${aws_iam_access_key.cg_dev_user_key.secret}"
  sensitive = true
}

#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}