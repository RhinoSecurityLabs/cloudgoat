// https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/resources/db_instance
resource "aws_db_instance" "cg-rds-db_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  identifier           = "cg-rds"
  username             = var.rds-username
  password             = var.rds-password
  parameter_group_name = "default.mysql5.7"

  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.cg-db-subnet-group.name

  vpc_security_group_ids = [aws_security_group.allow_mysql.id]

  publicly_accessible = false

  tags = {
    Name = "cg-rds-db_instance-${var.cgid}"
  }
}

// https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/resources/db_snapshot
resource "aws_db_snapshot" "cg-rds_snapshot" {
  db_instance_identifier = aws_db_instance.cg-rds-db_instance.identifier
  db_snapshot_identifier = "cg-rds-snapshot"

  depends_on = [aws_instance.cg-ec2-instance]

  tags = {
    Name = "cg-rds_snapshot-${var.cgid}"
  }
}
