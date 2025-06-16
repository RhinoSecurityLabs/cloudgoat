#Security Groups
resource "aws_security_group" "lb_http" {
  name        = "cg-lb-http-${local.cgid_suffix}"
  description = "CloudGoat ${var.cgid} Security Group for Application Load Balancer over HTTP"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "cg-lb-http-${local.cgid_suffix}"
  }
}


#Application Load Balancer
resource "aws_lb" "this" {
  name               = "cg-lb-${local.cgid_suffix}"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  access_logs {
    bucket  = aws_s3_bucket.logs.bucket
    prefix  = "cg-lb-logs"
    enabled = true
  }
  security_groups = [
    aws_security_group.lb_http.id
  ]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

#Target Group
resource "aws_lb_target_group" "this" {
  # Note: the name cannot be more than 32 characters
  name        = "cg-tg-${local.cgid_suffix}"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"
}

#Target Group Attachment
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.ubuntu.id
  port             = 9000
}

#Load Balancer Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
