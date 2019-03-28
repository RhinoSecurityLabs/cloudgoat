resource "aws_elb" "lb" {
  name = "cloudgoat-elb"
  availability_zones = ["${var.availability_zone}"]

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  security_groups             = ["${aws_security_group.cloudgoat_lb_sg.id}"]
  instances                   = ["${aws_instance.cloudgoat_instance.*.id}"]
}

resource "aws_security_group" "cloudgoat_lb_sg" {
  name = "cloudgoat_lb_sg"
  description = "SG for ELB"
}

resource "aws_security_group_rule" "traffic_in" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["${file("../tmp/allow_cidr.txt")}"]
  security_group_id = "${aws_security_group.cloudgoat_lb_sg.id}"
}

resource "aws_security_group_rule" "traffic_to_instance" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
  security_group_id = "${aws_security_group.cloudgoat_lb_sg.id}"
}
