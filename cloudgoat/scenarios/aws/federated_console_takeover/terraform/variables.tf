## Variables for federated_console_takeover scenario

variable "profile" {
  description = "The AWS profile to use when deploying resources"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources into"
  default     = "us-east-1"
  type        = string

  validation {
    condition     = can(regex("^(us-east-1|us-west-1|us-west-2|eu-west-1|eu-central-1)$", var.region))
    error_message = "The region must be a valid AWS region where all required services are available."
  }
}

variable "cgid" {
  description = "CGID variable for unique naming between scenarios"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{6,20}$", var.cgid))
    error_message = "The cgid must be 6-20 lowercase alphanumeric characters."
  }
}

variable "cg_whitelist" {
  description = "User's public IP address(es) for restricting access to resources"
  type        = list(string)
}

# VPC and networking variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
  type        = string
}

# EC2 variables
variable "ec2_instance_type" {
  description = "Instance type for EC2 instance"
  default     = "t3.micro"
  type        = string

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.ec2_instance_type)
    error_message = "The instance type must be t2.micro or t3.micro to stay within free tier limits."
  }
}

# Stack naming variables required by CloudGoat
variable "stack-name" {
  description = "Name of the stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario being deployed"
  default     = "federated_console_takeover"
  type        = string
} 