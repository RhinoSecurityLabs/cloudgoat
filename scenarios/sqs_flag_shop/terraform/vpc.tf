resource "aws_vpc" "vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "cg-${var.cgid}"
  }
}


resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "cg-${var.cgid}"
  }
}


# Public Subnets
resource "aws_subnet" "public_1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.10.10.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "cg-${var.cgid}-public-1"
  }
}

resource "aws_subnet" "public_2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.10.20.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "cg-${var.cgid}-public-2"
  }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  availability_zone = "${var.region}a"
  cidr_block        = "10.10.30.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "cg-${var.cgid}-private-1"
  }
}

resource "aws_subnet" "private_2" {
  availability_zone = "${var.region}b"
  cidr_block        = "10.10.40.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "cg-${var.cgid}-private-2"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "cg-${var.cgid}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "cg-${var.cgid}-private"
  }
}


resource "aws_route_table_association" "public_1" {
  for_each = {
    1 = aws_subnet.public_1.id
    2 = aws_subnet.public_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = {
    1 = aws_subnet.private_1.id
    2 = aws_subnet.private_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}
