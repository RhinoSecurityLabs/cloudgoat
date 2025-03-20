resource "aws_vpc" "cg-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "cg-internet-gateway" {
  vpc_id = aws_vpc.cg-vpc.id
}

resource "aws_route_table" "cg-public-subnet-route-table" {
  vpc_id = aws_vpc.cg-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cg-internet-gateway.id
  }
}

resource "aws_main_route_table_association" "cg-public-subnet-1-route-association" {
  vpc_id = aws_vpc.cg-vpc.id
  route_table_id = aws_route_table.cg-public-subnet-route-table.id
}

resource "aws_security_group" "cg-ec2-ssh-security-group" {
  name        = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
  vpc_id      = aws_vpc.cg-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  description = "Allow inbound traffic on MySQL port"
  vpc_id = aws_vpc.cg-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = concat([aws_vpc.cg-vpc.cidr_block], var.cg_whitelist)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "cg-subnet-1" {
  vpc_id = aws_vpc.cg-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "cg-subnet-2" {
  vpc_id = aws_vpc.cg-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_db_subnet_group" "cg-db-subnet-group" {
  name       = "cg-db-subnet-group"
  subnet_ids = [aws_subnet.cg-subnet-1.id, aws_subnet.cg-subnet-2.id]
}
