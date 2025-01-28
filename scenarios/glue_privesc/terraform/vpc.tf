resource "aws_vpc" "vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "CloudGoat ${var.cgid} VPC"
  }
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "CloudGoat ${var.cgid}"
  }
}


resource "aws_subnet" "public_1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.10.10.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "CloudGoat ${var.cgid} Public a"
  }
}

resource "aws_subnet" "public_2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.10.20.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "CloudGoat ${var.cgid} Public b"
  }
}


resource "aws_subnet" "private_1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.10.30.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "CloudGoat ${var.cgid} Private a"
  }
}

resource "aws_subnet" "private_2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.10.40.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "CloudGoat ${var.cgid} Private 2"
  }
}


resource "aws_route_table" "public_subnet" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "CloudGoat ${var.cgid} Route Table for Public Subnet"
  }
}

resource "aws_route_table" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "CloudGoat ${var.cgid} Route Table for Private Subnet"
  }
}


resource "aws_route_table_association" "public_subnet" {
  for_each = {
    1 = aws_subnet.public_1.id,
    2 = aws_subnet.public_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.public_subnet.id
}

resource "aws_route_table_association" "private_subnet" {
  for_each = {
    1 = aws_subnet.private_1.id,
    2 = aws_subnet.private_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private_subnet.id
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.public_subnet.id
  ]
}

resource "aws_vpc_endpoint" "glue" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.glue"
  vpc_endpoint_type = "Interface"
}
