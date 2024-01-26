#Required: Always output the AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

#Example: IAM User Access Key
output "cloudgoat_output_johnsmith_access_key_id" {
  value = aws_iam_access_key.cg_johnsmith.id
}

#Example: IAM User Secret Key
output "cloudgoat_output_johnsmith_secret_key" {
  value = aws_iam_access_key.cg_johnsmith.secret
}

#Example: output for an SSH key
output "cloudgoat_output_ssh_keyname" {
  value = "An SSH key-pair named ${var.ssh_public_key} has been generated stored in this directory."
}

#Example: Always output any important URLs, IPs, or other such infromation
output "cloudgoat_output_load_balancer_url" {
  value = aws_lb.cg_lb.dns_name
}
