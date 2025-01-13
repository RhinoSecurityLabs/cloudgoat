resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.this.id
  db_name              = var.rds_database_name
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = "default.postgres16"
  publicly_accessible  = false
  skip_final_snapshot  = true

  port = "5432"

  storage_encrypted = true

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]
}

resource "aws_db_subnet_group" "this" {
  name        = "cg-rds-subnet-group-${var.cgid}"
  description = "CloudGoat ${var.cgid} Subnet Group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}
