# Create a VPC
resource "aws_vpc" "cg_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false
  tags = {
    Name = "cg-vpc-${var.cgid}"
  }
}

# Create a private subnet
resource "aws_subnet" "cg_private_subnet" {
  vpc_id                  = aws_vpc.cg_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false        # No public IPs
  tags = {
    Name = "cg-private-subnet-${var.cgid}"
  }
}

# Basic VPC outputs
output "vpc_id" {
  value = aws_vpc.cg_vpc.id
}

output "subnet_id" {
  value = aws_subnet.cg_private_subnet.id
}
