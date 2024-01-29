resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.150.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "cg-${var.cgid}-main"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "cg-${var.cgid}-main"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.current_az.names[0]
  cidr_block        = "192.168.150.0/26"

  tags = {
    "Name" = "cg-${var.cgid}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name" = "cg-${var.cgid}-public"
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2
# Allow http from whitelist IP.
# Allow All outbound.
resource "aws_security_group" "allow_http" {
  name        = "cg-${var.cgid}-allow-http"
  description = "Allow inbound traffic on port 80 from whitelist IP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-allow-http-${var.cgid}"
  }
}