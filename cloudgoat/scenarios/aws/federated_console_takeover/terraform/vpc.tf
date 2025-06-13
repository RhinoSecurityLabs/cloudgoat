# VPC Configuration for federated_console_takeover scenario

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true  # Required for VPC endpoints with private DNS
  enable_dns_hostnames = true  # Required for VPC endpoints with private DNS
  
  tags = {
    Name = "cg-vpc-${var.cgid}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "cg-igw-${var.cgid}"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cg-subnet-${var.cgid}"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "cg-route-table-${var.cgid}"
  }
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

# VPC Endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.subnet.id]
  
  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "cg-ssm-endpoint-${var.cgid}"
  }
}

# VPC Endpoint for SSM Messages
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.subnet.id]
  
  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "cg-ssm-messages-endpoint-${var.cgid}"
  }
}

# VPC Endpoint for EC2 Messages
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.subnet.id]
  
  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "cg-ec2-messages-endpoint-${var.cgid}"
  }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "cg-vpc-endpoint-sg-${var.cgid}"
  description = "Allow TLS inbound traffic for VPC endpoints"
  vpc_id      = aws_vpc.vpc.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "cg-vpc-endpoint-sg-${var.cgid}"
  }
} 