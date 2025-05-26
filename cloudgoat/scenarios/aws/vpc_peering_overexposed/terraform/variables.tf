## Variables for vpc_peering_overexposed scenario

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
variable "dev_vpc_cidr" {
  description = "CIDR block for the Dev VPC"
  default     = "10.10.0.0/16"
  type        = string
}

variable "prod_vpc_cidr" {
  description = "CIDR block for the Prod VPC"
  default     = "10.20.0.0/16"
  type        = string
}

variable "dev_subnet_cidr" {
  description = "CIDR block for the Dev subnet"
  default     = "10.10.10.0/24"
  type        = string
}

variable "prod_subnet_cidr" {
  description = "CIDR block for the Prod subnet"
  default     = "10.20.10.0/24"
  type        = string
}

variable "prod_db_subnet_cidr" {
  description = "CIDR block for the Prod DB subnet"
  default     = "10.20.20.0/24"
  type        = string
}

# EC2 variables
variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  default     = "t2.micro"
  type        = string

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.ec2_instance_type)
    error_message = "The instance type must be t2.micro or t3.micro to stay within free tier limits."
  }
}

# Database variables
variable "db_instance_class" {
  description = "Instance class for RDS MySQL"
  default     = "db.t3.micro"
  type        = string

  validation {
    condition     = contains(["db.t2.micro", "db.t3.micro"], var.db_instance_class)
    error_message = "The database instance class must be db.t2.micro or db.t3.micro to stay within free tier limits."
  }
}

variable "db_name" {
  description = "Name of the MySQL database"
  default     = "customerdb"
  type        = string
}

variable "db_username" {
  description = "Username for MySQL database"
  default     = "admin"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for MySQL database (auto-generated if not provided)"
  type        = string
  default     = "Sup3rSecr3tPassw0rd1"
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "The database password must be at least 8 characters long."
  }
}

# User credentials
variable "initial_username" {
  description = "Username for the initial IAM user"
  default     = "cguser"
  type        = string
}

# Stack naming variables required by CloudGoat
variable "stack-name" {
  description = "Name of the stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario being deployed"
  default     = "vpc_peering_overexposed"
  type        = string
} 