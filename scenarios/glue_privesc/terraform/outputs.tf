output "cg-glue-web-user-access_key" {
  value = aws_iam_access_key.cg-run-app_access_key.id
}

output "cg-glue-web-user-secret_key" {
  value     = aws_iam_access_key.cg-run-app_access_key.secret
  sensitive = true
}

output "cg_web_site_ip" {
  value = aws_instance.cg-ubuntu-ec2.public_ip
}