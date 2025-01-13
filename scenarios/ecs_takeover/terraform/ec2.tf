data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  user_data = <<EOH
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
EOH
}

resource "aws_instance" "vulnsite" {
  ami                         = data.aws_ami.ecs.id
  iam_instance_profile        = aws_iam_instance_profile.ecs_agent.name
  vpc_security_group_ids      = [aws_security_group.ecs_sg.id]
  user_data                   = local.user_data
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id

  tags = {
    "Name" = "cg-${var.scenario-name}-${var.cgid}-vulnsite"
  }
}

resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ecs.id
  iam_instance_profile        = aws_iam_instance_profile.ecs_agent.name
  vpc_security_group_ids      = [aws_security_group.ecs_sg.id]
  user_data                   = local.user_data
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id

  tags = {
    "Name" = "cg-${var.scenario-name}-${var.cgid}-vault"
  }
}
