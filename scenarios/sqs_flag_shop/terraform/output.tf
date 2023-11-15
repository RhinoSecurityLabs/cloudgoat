output "cloudgoat_output_sqsuser_access_key_id" {
  value = aws_iam_access_key.cg-sqs-user_access_key.id
}

output "cloudgoat_output_sqsuser_secret_key" {
  value     = aws_iam_access_key.cg-sqs-user_access_key.secret
  sensitive = true
}

output "cg_web_site_ip" {
  value = "${aws_instance.cg_flag_shop_server.public_ip}:5000"
}