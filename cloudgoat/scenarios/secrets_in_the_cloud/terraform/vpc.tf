resource "aws_vpc" "cg_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cg-vpc-${var.cgid}"
  }
}

resource "aws_internet_gateway" "cg_igw" {
  vpc_id = aws_vpc.cg_vpc.id
  tags = {
    Name = "cg-igw-${var.cgid}"
  }
}

resource "aws_subnet" "cg_subnet" {
  vpc_id                  = aws_vpc.cg_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # or dynamically get a random availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "cg-subnet-${var.cgid}"
  }
}

resource "aws_route_table" "cg_route_table" {
  vpc_id = aws_vpc.cg_vpc.id
  tags = {
    Name = "cg-route-table-${var.cgid}"
  }
}

resource "aws_route" "cg_route" {
  route_table_id         = aws_route_table.cg_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cg_igw.id
}

resource "aws_route_table_association" "cg_route_table_association" {
  subnet_id      = aws_subnet.cg_subnet.id
  route_table_id = aws_route_table.cg_route_table.id
}
