resource "aws_vpc" "main" {
  cidr_block       = "3.84.104.0/24"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames  = true 
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

// VPC ENDPOINTS BELOW
resource "aws_vpc_endpoint" "sts" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids = [aws_subnet.main.id]
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

// resource "aws_vpc_endpoint" "ec2" {
//   vpc_id       = aws_vpc.main.id
//   service_name = "com.amazonaws.${var.region}.ec2"
//   vpc_endpoint_type = "Interface"
//   subnet_ids = ["${aws_subnet.main.id}"]
//   private_dns_enabled = true
//   security_group_ids = [
//     aws_security_group.main.id,
//   ]

//   tags = {
//     tag-key = "${var.cgid}"
//   }
// }

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids = [aws_subnet.main.id]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.main.id,
  ]

  tags = {
    tag-key = var.cgid
  }
}