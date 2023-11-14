output "cg_web_site_ip" {
  value = aws_instance.cg-ubuntu-ec2.public_ip
}