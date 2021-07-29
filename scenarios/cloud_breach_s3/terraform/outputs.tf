
#Required: Always output the AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}
output "cloudgoat_output_target_ec2_server_ip" {
  value = "${aws_instance.ec2-vulnerable-proxy-server.public_ip}"
}
output "definition_of_done" {
  value = <<EOT
  This lab is considered done once you can read out the file 'cardholders_corporate.csv'
  EOT
}