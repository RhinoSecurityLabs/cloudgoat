# outputs.tf

output "Website In Scope" {
  description = "The URL of the target web server."
  value       = "http://${aws_instance.instance.public_dns}"
}