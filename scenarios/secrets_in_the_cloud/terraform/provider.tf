# This Terraform file initializes the Terraform AWS provider (aka plugin).

provider "aws" {
  profile = "${var.profile}"
  region = "${var.region}"
}
