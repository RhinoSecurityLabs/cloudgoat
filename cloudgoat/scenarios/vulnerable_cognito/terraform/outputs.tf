output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.aws-account-id.account_id
}

output "apigateway_url" {
  value = "https://${aws_api_gateway_rest_api.MyS3.id}.execute-api.${var.region}.amazonaws.com/vulncognito/${aws_s3_bucket.cognito_s3.id}/index.html"
}
