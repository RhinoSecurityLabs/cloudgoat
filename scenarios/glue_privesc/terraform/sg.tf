

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

resource "aws_security_group_rule" "attache_source_group" {
  type        = "outbound"
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

