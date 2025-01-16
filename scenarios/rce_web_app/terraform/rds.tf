#Security Group
resource "aws_security_group" "cg-rds-security-group" {
  name        = "cg-rds-psql-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for PostgreSQL RDS Instance"
  vpc_id      = aws_vpc.cg-vpc.id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.10.0/24",
      "10.0.20.0/24",
      "10.0.30.0/24",
      "10.0.40.0/24"
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = merge(local.default_tags, {
    Name = "cg-rds-psql-${var.cgid}"
  })
}

#RDS Subnet Group
resource "aws_db_subnet_group" "cg-rds-subnet-group" {
  name        = "cloud-goat-rds-subnet-group-${var.cgid}"
  description = "CloudGoat ${var.cgid} Subnet Group"

  subnet_ids = [
    aws_subnet.cg-private-subnet-1.id,
    aws_subnet.cg-private-subnet-2.id
  ]
  tags = merge(local.default_tags, {
    Name = "cloud-goat-rds-subnet-group-${var.cgid}"
  })
}

#RDS PostgreSQL Instance
resource "aws_db_instance" "cg-psql-rds" {
  identifier           = "cg-rds-instance-${local.cgid_suffix}"
  engine               = "postgres"
  engine_version       = "12"
  port                 = "5432"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.cg-rds-subnet-group.id
  multi_az             = false
  username             = var.rds-username
  password             = var.rds-password
  publicly_accessible  = false
  vpc_security_group_ids = [
    aws_security_group.cg-rds-security-group.id
  ]
  storage_type        = "gp2"
  allocated_storage   = 20
  db_name             = "cloudgoat"
  apply_immediately   = true
  skip_final_snapshot = true

  tags = merge(local.default_tags, {
    Name = "cg-rds-instance-${var.cgid}"
  })
}
