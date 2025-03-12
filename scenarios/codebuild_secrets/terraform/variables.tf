#Required: AWS Profile
variable "profile" {

}
#Required: AWS Region
variable "region" {
  default = "us-east-1"
}
#Required: CGID Variable for unique naming
variable "cgid" {

}
#Example: RDS PostgreSQL Instance Credentials
variable "rds-username" {
  default = "cgadmin"
}
variable "rds-password" {
  default = "wagrrrrwwgahhhhwwwrrggawwwwwwrr"
}
variable "rds-database-name" {
  default = "securedb"
}
#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../cloudgoat.pub"
}
#Required: User's Public IP Address(es)
variable "cg_whitelist" {
  default = "../whitelist.txt"
}
#Stack Name
variable "stack-name" {
  default = "CloudGoat"
}
#Scenario Name
variable "scenario-name" {
  default = "codebuild-secrets"
}

locals {
  # Ensure the bucket suffix doesn't contain invalid characters
  # "Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  # (per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
  cgid_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}