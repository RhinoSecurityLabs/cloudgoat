resource "aws_alb" "website-alb" {
  name               = "website-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_subnet.id, aws_subnet.pub_subnet2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "example-saas-production-alb"
  }
}

resource "aws_alb_target_group" "website-tg" {
  name     = "website-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_alb_listener" "nginx-listeners" {
  load_balancer_arn = aws_alb.website-alb.arn
  port              = "80"
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.website-tg.arn
  }
}