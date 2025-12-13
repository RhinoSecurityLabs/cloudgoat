# outputs.tf

output "website_in_scope" {
  description = "The URL of the target web server."
  value       = "http://${aws_instance.instance.public_dns}"
}