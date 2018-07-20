resource "aws_lightsail_instance" "cloudgoat_ls" {
  name              = "cloudgoat_ls"
  availability_zone = "${var.availability_zone}"
  blueprint_id      = "amazon_linux_2017_03_1_1"
  bundle_id         = "micro_1_0"
  key_pair_name     = "${aws_lightsail_key_pair.cloudgoat_key_pair.name}"
}

resource "aws_lightsail_key_pair" "cloudgoat_key_pair" {
  name = "cloudgoat_key_pair"
}
