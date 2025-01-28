output "cloudgoat_output_sqsuser_access_key_id" {
  value = aws_iam_access_key.sqs.id
}

output "cloudgoat_output_sqsuser_secret_key" {
  value     = aws_iam_access_key.sqs.secret
  sensitive = true
}

output "web_site_ip" {
  value = "http://${aws_instance.flag_shop_server.public_ip}:5000"
}
