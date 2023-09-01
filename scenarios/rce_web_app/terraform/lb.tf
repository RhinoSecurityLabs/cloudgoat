#Security Groups
resource "aws_security_group" "cg-lb-http-security-group" {
  name        = "cg-lb-http-${local.cgid_suffix}"
  description = "CloudGoat ${var.cgid} Security Group for Application Load Balancer over HTTP"
  vpc_id      = aws_vpc.cg-vpc.id
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
  tags = merge(local.default_tags, {
    Name = "cg-lb-http-${local.cgid_suffix}"
  })
}

#Application Load Balancer
resource "aws_lb" "cg-lb" {
  name               = "cg-lb-${local.cgid_suffix}"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  access_logs {
    bucket  = aws_s3_bucket.cg-logs-s3-bucket.bucket
    prefix  = "cg-lb-logs"
    enabled = true
  }
  security_groups = [
    aws_security_group.cg-lb-http-security-group.id
  ]
  subnets = [
    aws_subnet.cg-public-subnet-1.id,
    aws_subnet.cg-public-subnet-2.id
  ]
  tags = merge(local.default_tags, {
    Name = "cg-lb-${var.cgid}"
  })
}

#Target Group
resource "aws_lb_target_group" "cg-target-group" {
  # Note: the name cannot be more than 32 characters
  name        = "cg-tg-${local.cgid_suffix}"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cg-vpc.id
  target_type = "instance"
  tags = merge(local.default_tags, {
    Name = "cg-target-group-${local.cgid_suffix}"
  })
}

#Target Group Attachment
resource "aws_lb_target_group_attachment" "cg-target-group-attachment" {
  target_group_arn = aws_lb_target_group.cg-target-group.arn
  target_id        = aws_instance.cg-ubuntu-ec2.id
  port             = 9000
}

#Load Balancer Listener
resource "aws_lb_listener" "cg-lb-listener" {
  load_balancer_arn = aws_lb.cg-lb.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cg-target-group.arn
  }
}