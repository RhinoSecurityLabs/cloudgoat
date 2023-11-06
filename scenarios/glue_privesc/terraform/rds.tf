resource "aws_db_instance" "example_rds" {
  allocated_storage    = 20                   # 스토리지 크기 (GB)
  storage_type         = "gp2"                # 스토리지 유형
  engine               = "postgres"           # 데이터베이스 엔진 (예: MySQL, PostgreSQL, Oracle 등)
  engine_version       = "13.7"               # 데이터베이스 엔진 버전
  instance_class       = "db.t3.micro"        # 인스턴스 유형
  db_name              = "cg-rds-${var.cgid}" # 데이터베이스 이름
  username             = "postgres"           # 데이터베이스 사용자 이름
  password             = "bob12cgv"           # 데이터베이스 암호
  parameter_group_name = "default.postgres13" # 매개변수 그룹 이름 (엔진 및 버전에 따라 다름)
  publicly_accessible  = false

  port = 5432

  storage_encrypted = true
}

resource "aws_db_subnet_group" "cg-rds-subnet-group" {
  name       = "cg-rds-subnet-group-${var.cgid}"
  subnet_ids = [aws_subnet.cg-public-subnet-1.id, aws_subnet.cg-public-subnet-2.id]

  tags = {
    Name = "cg-rds-subnet-group-${var.cgid}"
  }
}


resource "aws_security_group" "cg-rds-glue-security-group" {
  name        = "cg-rds-glue-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  //vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name     = "cg-rds-glue-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}


resource "aws_security_group" "cg-rds-ec2-security-group" {
  name        = "cg-rds-ec2-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for RDS to EC2 Instance"
  //vpc_id = "${aws_vpc.cg-vpc.id}"

  tags = {
    Name     = "cg-rds-glue-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_security_group_rule" "attache_source_group" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # cidr_blocks = var.cg_whitelist
  security_group_id        = aws_security_group.cg-rds-ec2-security-group.id
  source_security_group_id = aws_security_group.cg-ec2-rds-security-group.id
  lifecycle {
    create_before_destroy = true
  }
}