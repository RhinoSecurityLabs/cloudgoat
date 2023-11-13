
resource "aws_security_group" "cg-rds-glue-security-group" {
  name        = "cg-rds-glue-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id      = aws_vpc.cg-vpc.id
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

resource "aws_security_group" "cg-ec2-ssh-security-group" {
  name = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
      from_port = 22
      to_port = 22
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
  tags = {
    Name = "cg-ec2-ssh-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

#resource "aws_security_group" "cg-ec2-rds-security-group" {
#  name        = "cg-ec2-rds-${var.cgid}"
#  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
#  vpc_id      = aws_vpc.cg-vpc.id
#
#  # 인바운드 규칙 설정 (EC2 -> RDS)
#  ingress {
#    from_port       = 5432
#    to_port         = 5432
#    protocol        = "tcp"
#    security_groups = [aws_security_group.cg-rds-ec2-security-group.id]
#  }
#
#  # 아웃바운드 규칙 설정 (RDS -> EC2)
#  egress {
#    from_port       = 0
#    to_port         = 0
#    protocol        = "-1"
#    security_groups = [aws_security_group.cg-rds-ec2-security-group.id]
#  }
#
#  tags = {
#    Name     = "cg-ec2-http-${var.cgid}"
#    Stack    = "${var.stack-name}"
#    Scenario = "${var.scenario-name}"
#  }
#}
#
#resource "aws_security_group" "cg-rds-ec2-security-group" {
#  name        = "cg-rds-ec2-${var.cgid}"
#  description = "CloudGoat ${var.cgid} Security Group for RDS to EC2 Instance"
#  vpc_id      = aws_vpc.cg-vpc.id
#
#  # 인바운드 규칙 설정 (RDS -> EC2)
#  ingress {
#    from_port       = 0
#    to_port         = 0
#    protocol        = "-1"
#    security_groups = [aws_security_group.cg-ec2-rds-security-group.id]
#  }
#
#  # 아웃바운드 규칙 설정 (EC2 -> RDS)
#  egress {
#    from_port       = 5432 # RDS 데이터베이스 포트
#    to_port         = 5432 # RDS 데이터베이스 포트
#    protocol        = "tcp"
#    security_groups = [aws_security_group.cg-ec2-rds-security-group.id]
#  }
#
#  tags = {
#    Name     = "cg-rds-glue-${var.cgid}"
#    Stack    = "${var.stack-name}"
#    Scenario = "${var.scenario-name}"
#  }
#}
