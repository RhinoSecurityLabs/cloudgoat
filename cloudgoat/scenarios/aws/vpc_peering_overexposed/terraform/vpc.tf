## VPC and Networking Configuration for vpc_peering_overexposed scenario

# Dev VPC with public subnet
resource "aws_vpc" "dev_vpc" {
  cidr_block           = var.dev_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "dev-vpc-${var.cgid}"
    Environment = "Development"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev-igw-${var.cgid}"
  }
}

resource "aws_subnet" "dev_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = var.dev_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "dev-subnet-${var.cgid}"
    Environment = "Development"
  }
}

resource "aws_route_table" "dev_route_table" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev-route-table-${var.cgid}"
  }
}

resource "aws_route" "dev_internet_route" {
  route_table_id         = aws_route_table.dev_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_route_association" {
  subnet_id      = aws_subnet.dev_subnet.id
  route_table_id = aws_route_table.dev_route_table.id
}

# Prod VPC with private subnet
resource "aws_vpc" "prod_vpc" {
  cidr_block           = var.prod_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "prod-vpc-${var.cgid}"
    Environment = "Production"
  }
}

resource "aws_subnet" "prod_subnet" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = var.prod_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false # Private subnet

  tags = {
    Name        = "prod-subnet-${var.cgid}"
    Environment = "Production"
  }
}

resource "aws_subnet" "prod_db_subnet" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = var.prod_db_subnet_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false # Private subnet

  tags = {
    Name        = "prod-db-subnet-${var.cgid}"
    Environment = "Production"
  }
}

resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod-route-table-${var.cgid}"
  }
}

resource "aws_route_table_association" "prod_route_association" {
  subnet_id      = aws_subnet.prod_subnet.id
  route_table_id = aws_route_table.prod_route_table.id
}

resource "aws_route_table_association" "prod_db_route_association" {
  subnet_id      = aws_subnet.prod_db_subnet.id
  route_table_id = aws_route_table.prod_route_table.id
}

# VPC Peering Connection - Intentionally misconfigured to allow all traffic between VPCs
resource "aws_vpc_peering_connection" "dev_to_prod" {
  vpc_id      = aws_vpc.dev_vpc.id
  peer_vpc_id = aws_vpc.prod_vpc.id
  auto_accept = true

  tags = {
    Name = "dev-to-prod-peering-${var.cgid}"
  }
}

# Misconfigured route tables to allow overly permissive access between VPCs
resource "aws_route" "dev_to_prod_route" {
  route_table_id            = aws_route_table.dev_route_table.id
  destination_cidr_block    = var.prod_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.dev_to_prod.id
}

resource "aws_route" "prod_to_dev_route" {
  route_table_id            = aws_route_table.prod_route_table.id
  destination_cidr_block    = var.dev_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.dev_to_prod.id
}

# Security Groups
resource "aws_security_group" "dev_sg" {
  name        = "dev-security-group-${var.cgid}"
  description = "Security group for Dev EC2 instance"
  vpc_id      = aws_vpc.dev_vpc.id

  # Allow SSH from whitelisted IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sg-${var.cgid}"
  }
}

resource "aws_security_group" "prod_sg" {
  name        = "prod-security-group-${var.cgid}"
  description = "Security group for Prod EC2 instance"
  vpc_id      = aws_vpc.prod_vpc.id

  # Misconfigured to allow SSH from Dev VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.dev_vpc_cidr]
  }

  # Allow SSM connections
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.dev_vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-sg-${var.cgid}"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-security-group-${var.cgid}"
  description = "Security group for RDS MySQL instance"
  vpc_id      = aws_vpc.prod_vpc.id

  # Allow MySQL connections only from Prod subnet
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.prod_subnet_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg-${var.cgid}"
  }
}

# VPC Endpoints for SSM in the Production VPC
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm-endpoint-sg-${var.cgid}"
  description = "Security group for SSM VPC endpoints"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.prod_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm-endpoint-sg-${var.cgid}"
  }
}

# SSM Endpoints - Required for SSM to work in a private subnet
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.prod_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.prod_subnet.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]

  tags = {
    Name = "ssm-endpoint-${var.cgid}"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.prod_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.prod_subnet.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]

  tags = {
    Name = "ssm-messages-endpoint-${var.cgid}"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.prod_vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.prod_subnet.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]

  tags = {
    Name = "ec2-messages-endpoint-${var.cgid}"
  }
}

# S3 Gateway Endpoint for the Prod VPC to allow package installation
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.prod_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.prod_route_table.id]

  tags = {
    Name = "s3-endpoint-${var.cgid}"
  }
} 