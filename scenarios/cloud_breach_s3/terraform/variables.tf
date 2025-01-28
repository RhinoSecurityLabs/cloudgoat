#Required: AWS Profile
variable "profile" {
  description = "The AWS profile to use."
  type        = string
}

#Required: AWS Region
variable "region" {
  description = "The AWS region to deploy resources to."
  default     = "us-east-1"
  type        = string
}

#Required: CGID Variable for unique naming
variable "cgid" {
  description = "CGID variable for unique naming."
  type        = string
}

#Required: User's Public IP Address(es)
variable "cg_whitelist" {
  description = "User's public IP address, pulled from the file ../whitelist.txt"
  type        = list(any)
}

#SSH Public Key
variable "ssh-public-key-for-ec2" {
  description = "Where to store the public key"
  default     = "../cloudgoat.pub"
  type        = string
}

#SSH Private Key
variable "ssh-private-key-for-ec2" {
  description = "Where to store the private key"
  default     = "../cloudgoat"
  type        = string
}

#Stack Name
variable "stack-name" {
  description = "Name of the stack."
  default     = "CloudGoat"
  type        = string
}

#Scenario Name
variable "scenario-name" {
  description = "Name of the scenario."
  default     = "cloud-breach-s3"
  type        = string
}
