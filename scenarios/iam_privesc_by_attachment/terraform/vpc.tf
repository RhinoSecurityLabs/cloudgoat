#VPC
resource "aws_vpc" "cg-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
      Name = "CloudGoat ${var.cgid} VPC"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Internet Gateway
resource "aws_internet_gateway" "cg-internet-gateway" {
  vpc_id = "${aws_vpc.cg-vpc.id}"
  tags = {
      Name = "CloudGoat ${var.cgid} Internet Gateway"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Public Subnet
resource "aws_subnet" "cg-public-subnet" {
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  cidr_block = "10.0.10.0/24"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  tags = {
      Name = "CloudGoat ${var.cgid} Public Subnet"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Public Subnet Routing Table
resource "aws_route_table" "cg-public-subnet-route-table" {
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.cg-internet-gateway.id}"
  }
  vpc_id = "${aws_vpc.cg-vpc.id}"
  tags = {
      Name = "CloudGoat ${var.cgid} Route Table for Public Subnet"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Public Subnet Routing Association
resource "aws_route_table_association" "cg-public-subnet-route-association" {
  subnet_id = "${aws_subnet.cg-public-subnet.id}"
  route_table_id = "${aws_route_table.cg-public-subnet-route-table.id}"
}