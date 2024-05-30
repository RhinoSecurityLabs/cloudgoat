data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cg_sns_user_access_key_id" {
  value = aws_iam_access_key.cg-sns-user-key.id
}

output "cg_sns_user_secret_access_key" {
  value     = aws_iam_access_key.cg-sns-user-key.secret
  sensitive = true
}

# Dev purposes
output "ec2_public_ip" {
  value = aws_instance.cg-sns-instance.public_ip
}

# Dev purposes 
output "api_gateway_url" {
  value = aws_api_gateway_deployment.cg_deployment.invoke_url
}
