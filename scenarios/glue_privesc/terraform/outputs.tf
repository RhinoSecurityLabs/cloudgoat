output "website_url" {
  description = "The URL of the website"
  value       = "http://${aws_instance.linux_ec2.public_ip}:5000"
}
