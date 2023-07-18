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

#Stack Name
variable "stack-name" {
  default = "CloudGoat"
}
#Scenario Name
variable "scenario-name" {
  default = "iam-privesc-by-ec2"
}

# AMI to use for EC2 instance
variable "ami_id" {
  description = "The ID of the AMI to use"
  default = "ami-06ca3ca175f37dd66"
}

# Instance type to use for EC2 instance
variable "instance_type" {
  description = "The type of instance to start"
  default     = "t2.micro"
}
