resource "aws_lightsail_instance" "cloudgoat_ls" {
  name              = "cloudgoat_ls"
  availability_zone = "us-east-1b"
  blueprint_id      = "string"
  bundle_id         = "string"
  key_pair_name     = "${var.lightsail_keypair}"
}
