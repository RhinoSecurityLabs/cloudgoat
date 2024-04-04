resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} VPC"
  })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Internet Gateway"
  })
}

resource "aws_subnet" "public" {
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  cidr_block              = "10.0.10.0/24"
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Public Subnet"
  })
}

resource "aws_route_table" "public_subnet" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Route Table for Public Subnet"
  })
}

resource "aws_route_table_association" "public_subnet_route_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_subnet.id
}
