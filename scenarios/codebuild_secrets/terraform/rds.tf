#Security Group
resource "aws_security_group" "cg-rds-security-group" {
  name = "cg-rds-psql-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for PostgreSQL RDS Instance"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = [
          "10.10.10.0/24",
          "10.10.20.0/24",
          "10.10.30.0/24",
          "10.10.40.0/24"
      ]
  }
  ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = var.cg_whitelist
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
}
#RDS Subnet Group
resource "aws_db_subnet_group" "cg-rds-subnet-group" {
  name = "cloud-goat-rds-subnet-group-${var.cgid}"
  subnet_ids = [
      "${aws_subnet.cg-private-subnet-1.id}",
      "${aws_subnet.cg-private-subnet-2.id}"
  ]
  description = "CloudGoat ${var.cgid} Subnet Group"
}
resource "aws_db_subnet_group" "cg-rds-testing-subnet-group" {
  name = "cloud-goat-rds-testing-subnet-group-${var.cgid}"
  subnet_ids = [
      "${aws_subnet.cg-public-subnet-1.id}",
      "${aws_subnet.cg-public-subnet-2.id}"
  ]
  description = "CloudGoat ${var.cgid} Subnet Group ONLY for Testing with Public Subnets"
}
#RDS PostgreSQL Instance
resource "aws_db_instance" "cg-psql-rds" {
  identifier = "cg-rds-instance-${var.cgid}"
  engine = "postgres"
  engine_version = "9.6"
  port = "5432"
  instance_class = "db.t2.micro"
  db_subnet_group_name = "${aws_db_subnet_group.cg-rds-subnet-group.id}"
  multi_az = false
  username = "${var.rds-username}"
  password = "${var.rds-password}"
  publicly_accessible = false
  vpc_security_group_ids = [
    "${aws_security_group.cg-rds-security-group.id}"
  ]
  storage_type = "gp2"
  allocated_storage = 20
  name = "${var.rds-database-name}"
  apply_immediately = true
  skip_final_snapshot = true

  tags = {
      Name = "cg-rds-instance-${var.cgid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}