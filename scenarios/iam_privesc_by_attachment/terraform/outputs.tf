#IAM User Credentials
output "cloudgoat_output_kerrigan_access_key_id" {
  value = "${aws_iam_access_key.cg-kerrigan.id}"
}
output "cloudgoat_output_kerrigan_secret_key" {
  value = "${aws_iam_access_key.cg-kerrigan.secret}"
  sensitive = true
}
#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}

output "cloudgoat_output_target_ec2_instance_tags" {
  value = "${aws_instance.cg-super-critical-security-server.tags}"
}

output "definition_of_done" {
  value = <<EOT
  This lab is considered done once you have terminated the super-critical-security-server ec2 instance. Tags for instance are specified above.
  EOT
}