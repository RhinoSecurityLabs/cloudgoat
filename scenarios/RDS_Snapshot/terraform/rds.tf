resource "aws_db_instance" "cg-rds-db_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = "cg-rds"
  username             = "admin"
  password             = "test1234"
  parameter_group_name = "default.mysql5.7"

  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.cg-db-subnet-group.name

  vpc_security_group_ids = [aws_security_group.allow_mysql.id]  // 'vpc.tf' 파일에서 생성한 보안 그룹을 참조합니다.

  publicly_accessible = true  // RDS 인스턴스가 공개적으로 접근 가능하도록 설정하세요.

  tags = {
    Name = "cg-rds-db_instance-${var.cgid}"
  }
}

resource "aws_db_snapshot" "cg-rds_snapshot" {
  db_instance_identifier = aws_db_instance.cg-rds-db_instance.identifier
  db_snapshot_identifier = "cg-rds-snapshot"
  tags = {
    Name = "cg-rds_snapshot-${var.cgid}"
  }
}
