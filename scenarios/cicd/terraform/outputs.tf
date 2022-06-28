output "cloudgoat_output_aws_account_id" {
  value = local.account_id
}

output "cloudgoat_output_api_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}

output "cloudgoat_output_access_key_id" {
  value     = aws_iam_access_key.initial.id
  sensitive = true
}
output "cloudgoat_output_secret_access_key" {
  value     = aws_iam_access_key.initial.secret
  sensitive = true
}