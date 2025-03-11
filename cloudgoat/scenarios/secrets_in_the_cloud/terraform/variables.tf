# This Terraform file creates the following variables:
# - A profile variable
# - A AWS region variable
# - A Cloudgoat ID variable
# - A Cloudgoat IP whitelist variable
# - A Public SSH key variable 
# - A Private SSH key variable
# - A 'stack' name variable
# - A scenario name variable

#Required: AWS Profile
variable "profile" {

}
#Required: AWS Region
variable "region" {
  default = "us-west-2"
}
#Required: CGID Variable for unique naming
variable "cgid" {

}
#Required: User's Public IP Address(es)
variable "cg_whitelist" {
  
}
#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../cloudgoat.pub"
}
#SSH Private Key
variable "ssh-private-key-for-ec2" {
  default = "../cloudgoat"
}
#Stack Name
variable "stack-name" {
  default = "CloudGoat"
}
#Scenario Name
variable "scenario-name" {
  default = "secrets_in_the_cloud"
}
