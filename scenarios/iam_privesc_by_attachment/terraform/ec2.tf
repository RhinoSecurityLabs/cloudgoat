#Security Groups
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
resource "aws_security_group" "cg-ec2-http-https-security-group" {
  name = "cg-ec2-http-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over HTTP"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  ingress {
      from_port = 443
      to_port = 443
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
    Name = "cg-ec2-http-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
#EC2 Instance
resource "aws_instance" "cg-super-critical-security-server" {
  ami = "ami-0a313d6098716f372"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.cg-public-subnet.id}"
  associate_public_ip_address = true
  vpc_security_group_ids = [
      "${aws_security_group.cg-ec2-ssh-security-group.id}",
      "${aws_security_group.cg-ec2-http-https-security-group.id}"
  ]
  root_block_device {
      volume_type = "gp2"
      volume_size = 8
      delete_on_termination = true
  }
  volume_tags = {
      Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
  tags = {
      Name = "CloudGoat ${var.cgid} super-critical-security-server EC2 Instance"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}