resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.this.id
  db_name              = var.database_name
  username             = var.database_username
  password             = var.database_password
  parameter_group_name = "default.mysql8.0"
  publicly_accessible  = false
  skip_final_snapshot  = true

  port = 3306

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
