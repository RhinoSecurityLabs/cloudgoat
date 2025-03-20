variable "profile" {
  description = "The AWS profile to use"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming"
  type        = string
}

variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
}

variable "region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

variable "stack-name" {
  description = "Name of the CloudGoat stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario"
  default     = "beanstalk_secrets"
  type        = string
}

# Additional scenario-specific variables

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2 recommended)"
  type        = string
  default     = "ami-0c94855ba95c71c99"
}

variable "instance_type" {
  description = "EC2 instance type for the simulated Elastic Beanstalk environment"
  type        = string
  default     = "t2.micro"
}

variable "final_flag" {
  description = "The final flag stored in Secrets Manager"
  type        = string
  default     = "FLAG{D0nt_st0r3_s3cr3ts_in_b3@nsta1k!}"
}
