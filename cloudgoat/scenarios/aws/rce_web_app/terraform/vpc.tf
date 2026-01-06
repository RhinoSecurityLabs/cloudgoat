#VPC
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "CloudGoat ${var.cgid}"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "CloudGoat ${var.cgid}"
  }
}


#Public Subnets
resource "aws_subnet" "public_1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.0.10.0/24"
  vpc_id            = aws_vpc.this.id
  tags = {
    Name = "CloudGoat Public Subnet #1"
  }
}

resource "aws_subnet" "public_2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.0.20.0/24"
  vpc_id            = aws_vpc.this.id
  tags = {
    Name = "CloudGoat Public Subnet #2"
  }
}

#Private Subnets
resource "aws_subnet" "private_1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.0.30.0/24"
  vpc_id            = aws_vpc.this.id
  tags = {
    Name = "CloudGoat Private Subnet #1"
  }
}

resource "aws_subnet" "private_2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.0.40.0/24"
  vpc_id            = aws_vpc.this.id
  tags = {
    Name = "CloudGoat Private Subnet #2"
  }
}


#Public Subnet Routing Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "CloudGoat Route Table for Public Subnet"
  }
}

#Private Subnet Routing Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "CloudGoat Route Table for Private Subnet"
  }
}


#Public Subnets Routing Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


#Private Subnets Routing Associations
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}