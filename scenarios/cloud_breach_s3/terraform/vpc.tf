resource "aws_vpc" "cg-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} VPC"
  })
}

#Internet Gateway
resource "aws_internet_gateway" "cg-internet-gateway" {
  vpc_id = aws_vpc.cg-vpc.id

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Internet Gateway"
  })
}

#Public Subnets
resource "aws_subnet" "cg-public-subnet-1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.10.10.0/24"
  vpc_id            = aws_vpc.cg-vpc.id

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Public Subnet #1"
  })
}

resource "aws_subnet" "cg-public-subnet-2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.10.20.0/24"
  vpc_id            = aws_vpc.cg-vpc.id

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Public Subnet #2"
  })
}

#Public Subnet Routing Table
resource "aws_route_table" "cg-public-subnet-route-table" {
  vpc_id = aws_vpc.cg-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cg-internet-gateway.id
  }

  tags = merge(local.default_tags, {
    Name = "CloudGoat ${var.cgid} Route Table for Public Subnet"
  })
}

#Public Subnets Routing Associations
resource "aws_route_table_association" "cg-public-subnet-1-route-association" {
  subnet_id      = aws_subnet.cg-public-subnet-1.id
  route_table_id = aws_route_table.cg-public-subnet-route-table.id
}

resource "aws_route_table_association" "cg-public-subnet-2-route-association" {
  subnet_id      = aws_subnet.cg-public-subnet-2.id
  route_table_id = aws_route_table.cg-public-subnet-route-table.id
}
