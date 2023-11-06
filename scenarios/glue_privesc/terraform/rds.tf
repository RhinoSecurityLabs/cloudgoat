resource "aws_db_instance" "cg-rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.cg-rds-subnet-group.id
  db_name              = var.rds-database-name
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = "default.postgres13"
  publicly_accessible  = false
  skip_final_snapshot  = true

  port = "5432"

  storage_encrypted = true

  vpc_security_group_ids = [
    aws_security_group.cg-rds-security-group.id,
  ]

  depends_on = [local_file.sql_file]
  tags = {
    Name     = "cg-rds-instance-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

data "local_file" "csv_file" {
  filename = "../assets/order_data2.csv"
}

resource "local_file" "sql_file" {
  content  = templatefile("${path.module}/../assets/sql_template.tpl", {
    csv_content           = data.local_file.csv_file.content,
    aws_access_key_id     = aws_iam_access_key.cg-glue-admin_access_key.id,
    aws_secret_access_key = aws_iam_access_key.cg-glue-admin_access_key.secret
  })
  filename = "../assets/insert_data.sql"
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