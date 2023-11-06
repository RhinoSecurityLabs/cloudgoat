output "cg-glue-web-user-access_key" {
  value = aws_iam_access_key.cg-run-app_access_key.id
}

output "cg-glue-web-user-secret_key" {
  value = aws_iam_access_key.cg-run-app_access_key.secret
}