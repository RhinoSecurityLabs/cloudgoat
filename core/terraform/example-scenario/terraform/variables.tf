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
#Required: User's Public IP Address(es)
variable "cg_whitelist" {
  type = list

}

#Example: RDS PostgreSQL Instance Credentials
variable "rds-username" {
  default = "cgadmin"
}
variable "rds-password" {
  default = "Purplepwny2029"
}
#Example: SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../cloudgoat.pub"
}
#Example: SSH Private Key
variable "ssh-private-key-for-ec2" {
  default = "../cloudgoat"
}