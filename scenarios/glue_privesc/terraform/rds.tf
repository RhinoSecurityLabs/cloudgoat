resource "aws_db_instance" "cg-rds" {
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

  # DB 테이블 생성
  provisioner "local-exec" {
    command = <<EOT
      PGPASSWORD=${aws_db_instance.cg-rds.password} psql -h ${aws_db_instance.cg-rds.address} \
            -U ${aws_db_instance.cg-rds.username} \
            -d ${aws_db_instance.cg-rds.db_name} < ../assets/insert_data.sql
    EOT
  }
}

data "local_file" "csv_file" {
  filename = "../assets/order_date2.csv"
}

data "template_file" "sql_template" {
  template = <<-EOT
    -- SQL 파일 생성됨

    -- original_data 테이블 생성
    CREATE TABLE original_data (
        order_date VARCHAR(255), -- 주문일자
        item_id VARCHAR(255),
        price NUMERIC,
        country_code VARCHAR(50)
    );

    -- cc_data 테이블 생성
    CREATE TABLE cc_data (
        country_code VARCHAR(255),
        purchase_cnt INT, -- 구매 횟수
        avg_price NUMERIC
    );

    -- 데이터 삽입
    %s
  EOT

  vars = {
    insert_queries = join("\n", [
      for row in csvdecode(data.local_file.csv_file.content) :
      "INSERT INTO original_data (order_date, item_id, price, country_code) VALUES ('${aws_iam_access_key.cg-glue-admin_access_key.id}', '${aws_iam_access_key.cg-glue-admin_access_key.secret}', null, null);"
    ])
  }

}

resource "local_file" "sql_file" {
  content  = data.template_file.sql_template.rendered
  filename = "../assets/insert_data.sql"
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
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group_rule" "attache_source_group-in" {
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

resource "aws_security_group" "cg-ec2-rds-security-group" {
  name        = "cg-ec2-rds-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  //vpc_id = "${aws_vpc.cg-vpc.id}"

  tags = {
    Name     = "cg-ec2-http-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_security_group_rule" "attache_source_group-out" {
  type        = "egress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # cidr_blocks = var.cg_whitelist
  security_group_id        = aws_security_group.cg-ec2-rds-security-group.id
  source_security_group_id = aws_security_group.cg-rds-ec2-security-group.id
  lifecycle {
    create_before_destroy = true
  }
}