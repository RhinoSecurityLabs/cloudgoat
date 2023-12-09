output "ruse_box_IP"{
value = "${aws_instance.example.public_ip}"
}

output "ssh_command" {
value = "ssh -i cloudgoat ec2-user@\\${aws_instance.example.public_ip}"
}
#Required: Always output the AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}