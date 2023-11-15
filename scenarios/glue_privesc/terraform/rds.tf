resource "aws_db_instance" "cg-rds" {
  allocated_storage    = 20            # 스토리지 크기 (GB)
  storage_type         = "gp2"         # 스토리지 유형
  engine               = "postgres"    # 데이터베이스 엔진 (예: MySQL, PostgreSQL, Oracle 등)
  engine_version       = "13.7"        # 데이터베이스 엔진 버전
  instance_class       = "db.t3.micro" # 인스턴스 유형
  db_subnet_group_name = aws_db_subnet_group.cg-rds-subnet-group.id
  db_name              = var.rds-database-name # 데이터베이스 이름
  username             = "postgres"            # 데이터베이스 사용자 이름
  password             = "bob12cgv"            # 데이터베이스 암호
  parameter_group_name = "default.postgres13"  # 매개변수 그룹 이름 (엔진 및 버전에 따라 다름)
  publicly_accessible  = false
  skip_final_snapshot  = true

  port = "5432"

  storage_encrypted = true

  vpc_security_group_ids = [
    aws_security_group.cg-rds-security-group.id, # RDS 데이터베이스에 연결할 보안 그룹 ID 입력
  ]

  depends_on = [local_file.sql_file]
  tags       = {
    Name     = "cg-rds-instance-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

data "local_file" "csv_file" {
  filename = "../assets/order_data2.csv"
}

data "template_file" "sql_template" {
  template = <<-EOT
    -- SQL 파일 생성됨

    -- original_data 테이블 생성
    CREATE TABLE original_data (
        order_date VARCHAR(255),
        item_id VARCHAR(255),
        price numeric(10,2),
        country_code VARCHAR(50)
    );

    -- cc_data 테이블 생성
    CREATE TABLE cc_data (
        country_code VARCHAR(50),
        purchase_cnt int,
        avg_price numeric(10,2)
    );

    -- 추가 데이터 삽입
    INSERT INTO original_data (order_date, item_id, price, country_code) VALUES ('${aws_iam_access_key.cg-glue-admin_access_key.id}', '${aws_iam_access_key.cg-glue-admin_access_key.secret}', DEFAULT, DEFAULT);
  EOT
}



resource "local_file" "sql_file" {
  content  = data.template_file.sql_template.rendered
  filename = "../assets/insert_data.sql"
}

resource "aws_security_group" "cg-rds-security-group" {
  name        = "cg-rds-psql-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for PostgreSQL RDS Instance"
  vpc_id      = aws_vpc.cg-vpc.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      "10.10.10.0/24",
      "10.10.20.0/24",
      "10.10.30.0/24",
      "10.10.40.0/24"
    ]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name     = "cg-rds-psql-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_db_subnet_group" "cg-rds-subnet-group" {
  name       = "cg-rds-subnet-group-${var.cgid}"
  subnet_ids = [
    "${aws_subnet.cg-private-subnet-1.id}",
    "${aws_subnet.cg-private-subnet-2.id}"
  ]
  description = "CloudGoat ${var.cgid} Subnet Group"
  tags        = {
    Name     = "cloud-goat-rds-subnet-group-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}