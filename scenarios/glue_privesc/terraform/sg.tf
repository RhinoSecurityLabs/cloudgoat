resource "aws_security_group" "cg-rds-glue-security-group" {
  name        = "cg-rds-glue-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id      = aws_vpc.cg-vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name     = "cg-rds-glue-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_security_group" "cg-ec2-security-group" {
  name        = "cg-ec2-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id      = aws_vpc.cg-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
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
    Name     = "cg-ec2-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_security_group" "cg-rds-security-group" {
  name        = "cg-rds-psql-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for PostgreSQL RDS Instance"
  vpc_id      = aws_vpc.cg-vpc.id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      "10.10.10.0/24",
      "10.10.20.0/24",
      "10.10.30.0/24",
      "10.10.40.0/24"
    ]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name     = "cg-rds-psql-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
