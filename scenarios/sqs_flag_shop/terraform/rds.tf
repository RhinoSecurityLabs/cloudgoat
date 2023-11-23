resource "aws_db_instance" "cg-rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql" # MySQL로 변경
  engine_version       = "8.0"   # MySQL 엔진 버전
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.cg-rds-subnet-group.id
  db_name              = var.rds-database-name
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = "default.mysql8.0" # MySQL 엔진 버전에 맞게 변경
  publicly_accessible  = false
  skip_final_snapshot  = true

  port = 3306 # MySQL의 기본 포트는 3306입니다.

  storage_encrypted = true

  vpc_security_group_ids = [
    aws_security_group.cg-rds-security-group.id,
  ]


  tags = {
    Name     = "cg-rds-instance-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}


resource "aws_db_subnet_group" "cg-rds-subnet-group" {
  name = "cg-rds-subnet-group-${var.cgid}"
  subnet_ids = [
    aws_subnet.cg-private-subnet-1.id,
    aws_subnet.cg-private-subnet-2.id
  ]
  description = "CloudGoat ${var.cgid} Subnet Group"
  tags = {
    Name     = "cloud-goat-rds-subnet-group-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "local_file" "sql_file" {
  content  = templatefile("${path.module}/../assets/init_rds.tpl",{})
  filename = "../assets/insert_data.sql"
}
