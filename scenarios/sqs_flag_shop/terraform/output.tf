output "cg_web_site_ip" {
  value = "${aws_instance.cg_flag_shop_server.public_ip}:5000"
}