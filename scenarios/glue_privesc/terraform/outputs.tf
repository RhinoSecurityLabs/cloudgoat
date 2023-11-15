output "cg_web_site_ip" {
  value = aws_instance.cg-linux-ec2.public_ip
}

output "cg_web_site_port" {
  value = 5000
}