resource "aws_vpc" "main" {
  cidr_block           = "3.84.104.0/24"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "3.84.104.0/24"

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_route_table" "subnet_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_route_table_association" "subnet_route_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.subnet_route_table.id
}

// VPC ENDPOINTS BELOW
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.main.id]
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}