# outputs.tf

output "Website_In_Scope_START_HERE" {
  description = "The URL of the target web server."
  # We reference the EIP now, which is guaranteed to exist
  value       = "http://${aws_eip.web_ip.public_ip}"
}