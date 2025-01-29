# Creating an ECS Cluster.
resource "aws_ecs_cluster" "cluster" {
  name = "cg-cluster-${var.cgid}"
}

# Setting up capacity providers for the ECS Cluster
# In consideration of the performance issues caused by EC2 created as t2.micro, we also added FARGATE for smooth scenario solving.
resource "aws_ecs_cluster_capacity_providers" "providers" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
    aws_ecs_capacity_provider.capacity_provider.name
  ]
}

# Defining an ECS capacity provider using an Auto Scaling group.
# ASG would have only one instance.
resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = "cg-provider-${var.cgid}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      target_capacity           = 50
    }
  }
}

# Defining an ECS capacity provider using an Auto Scaling group.
# ASG would have only one instance.
resource "aws_autoscaling_group" "asg" {
  name = "cg-asg-${var.cgid}"

  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public.id]

  tag {
    key                 = "Name"
    value               = "cg-ec2-instance-${var.cgid}"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Define EC2 launch template for ASG.
# ami            : Amazon Linux 2 for ECS
# instance type  : t2.micro
# security_group : allow http (whitelists apply), and all outbound.
# allow IMDSv1
resource "aws_launch_template" "template" {
  name          = "cg-launch-template-${var.cgid}"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_http.id]
  }

  metadata_options {
    http_tokens = "optional"
  }

  user_data = base64encode(
    <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config;
EOF
  )
}

# IAM Role for EC2 instance
resource "aws_iam_instance_profile" "profile" {
  name = "cg-ec2-role-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}

# Define ECS Service as vulnerable web.
# Web will be launch on container in EC2.
resource "aws_ecs_service" "ssrf_web_service" {
  name            = "cg-service-${var.cgid}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  launch_type     = "EC2"
  desired_count   = 1
}

# Define details for Web task.
# Bridge network for access EC2 metadata.
# Containers would be imported from ECR
resource "aws_ecs_task_definition" "web_task" {
  family                   = "cg-task-service-ssrf-web"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "512"
  depends_on               = [null_resource.docker_image]

  container_definitions = jsonencode([{
    name  = "cg-ssrf-web-${var.cgid}",
    image = "${aws_ecr_repository.repository.repository_url}:latest"

    portMappings = [{
      containerPort = 80,
      hostPort      = 80,
    }],

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"],
      interval    = 10,
      timeout     = 5,
      retries     = 3,
      startPeriod = 15
    }
  }])
}

# Wait a little for ec2 be created in ASG.
resource "time_sleep" "wait_for_instance" {
  depends_on = [aws_autoscaling_group.asg]
  create_duration = "30s"
}