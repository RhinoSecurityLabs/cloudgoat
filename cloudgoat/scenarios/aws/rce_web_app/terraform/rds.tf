#Security Group
resource "aws_security_group" "rds" {
  name        = "cg-rds-psql-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for PostgreSQL RDS Instance"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.this.cidr_block
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
}

#RDS Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "cloud-goat-rds-subnet-group-${var.cgid}"
  description = "CloudGoat ${var.cgid} Subnet Group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}

#RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier           = "cg-rds-instance-${local.cgid_suffix}"
  engine               = "postgres"
  engine_version       = "17"
  port                 = "5432"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.this.id
  multi_az             = false
  username             = var.rds_username
  password             = var.rds_password
  publicly_accessible  = false
  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]
  storage_type        = "gp2"
  allocated_storage   = 20
  db_name             = "cloudgoat"
  apply_immediately   = true
  skip_final_snapshot = true
}
