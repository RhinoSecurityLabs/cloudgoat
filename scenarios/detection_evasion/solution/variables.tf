variable "target_ip" {
  description = "The IP address you want to spoof."
}

variable "target_cidr_block" {
  description = "The IP address you want to spoof."
  default = "3.84.104.0/24"
}

variable "region" {
  description = "The AWS region to deploy resources to."
  default = "us-east-1"
}

variable "profile" {
  description = "The AWS profile to use."
}
