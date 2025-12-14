# outputs.tf

output "website_in_scope" {
  description = "The URL of the target web server."
  # We reference the EIP now, which is guaranteed to exist
  value       = "http://${aws_eip.web_ip.public_ip}"
}