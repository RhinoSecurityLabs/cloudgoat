resource "aws_vpc" "cg_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cg-vpc-${var.cgid}"
  }
}

resource "aws_subnet" "cg_subnet" {
  vpc_id     = aws_vpc.cg_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" # or dynamically get a random availability zone
  tags = {
    Name = "cg-subnet-${var.cgid}"
  }
}
