## RDS Configuration for vpc_peering_overexposed scenario

# Create DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "db-subnet-group-${var.cgid}"
  description = "Database subnet group for vpc_peering_overexposed scenario"
  subnet_ids  = [aws_subnet.prod_subnet.id, aws_subnet.prod_db_subnet.id]

  tags = {
    Name = "db-subnet-group-${var.cgid}"
  }
}

# Create RDS MySQL instance
resource "aws_db_instance" "customer_db" {
  identifier              = "customer-db-${var.cgid}"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true
  storage_encrypted       = false

  # Parameters for MySQL
  parameter_group_name = "default.mysql8.0"

  # Add lifecycle configuration to ensure clean destroy
  lifecycle {
    create_before_destroy = false
  }

  tags = {
    Name        = "customer-db-${var.cgid}"
    Environment = "Production"
    Sensitive   = "true"
  }
} 