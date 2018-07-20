resource "aws_lightsail_instance" "cloudgoat_ls" {
  name              = "cloudgoat_ls"
  availability_zone = "${var.availability_zone}"
  blueprint_id      = "amazon_linux_2017_03_1_1"
  bundle_id         = "micro_1_0"
  key_pair_name     = "${var.lightsail_keypair}"
}
