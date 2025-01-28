resource "aws_security_group" "ec2" {
  name        = "cg-ec2-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat([aws_vpc.vpc.cidr_block], var.cg_whitelist)
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = concat([aws_vpc.vpc.cidr_block], var.cg_whitelist)
  }
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-ec2-${var.cgid}"
  }
}


resource "aws_security_group" "rds" {
  name        = "cg-rds-mysql-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for MySQL RDS Instance"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      "10.10.10.0/24",
      "10.10.20.0/24",
      "10.10.30.0/24",
      "10.10.40.0/24"
    ]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "cg-rds-mysql-${var.cgid}"
  }
}


resource "aws_security_group" "lambda" {
  name        = "cg-lambda-${var.cgid}"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-lambda-${var.cgid}"
  }
}
