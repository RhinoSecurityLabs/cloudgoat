output "vuln-site" {
  value = aws_instance.vulnsite.public_dns
}

output "Start-Note" {
  value = "If a 503 error is returned by the ALB give a few mins for the website container to become active."
}