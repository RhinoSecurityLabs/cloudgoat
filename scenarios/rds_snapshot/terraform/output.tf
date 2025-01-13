output "ec2_IP"{
value = "${aws_instance.cg-ec2-instance.public_ip}"
}

output "ssh_command" {
  value = "ssh -i ${var.cgid}/cloudgoat ubuntu@${aws_instance.cg-ec2-instance.public_ip}"
}

output "cloudgoat_output_aws_account_id" {
  value = "${data.aws_caller_identity.aws-account-id.account_id}"
}