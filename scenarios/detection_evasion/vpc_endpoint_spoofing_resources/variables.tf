variable "target_IP" {
  description = "The IP address you want to spoof."
  default = "3.89.215.238"
}

variable "target_CIDR_block" {
  description = "The IP address you want to spoof."
  default = "3.89.215.0/24"
}

variable "region" {
  description = "The AWS region to deploy resources to."
  default = "us-east-1"
}

variable "profile" {
  description = "The AWS profile to use."
  default = "default"
}