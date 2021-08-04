resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.scenario-name}-${var.cgid}-cluster"
}

resource "aws_ecs_task_definition" "vault" {
  family = "cg-${var.scenario-name}-${var.cgid}-vault"

  # Wait for the website to be deployed to the cluster.
  # This should make sure the instances are available.
  container_definitions = jsonencode([
    {
      name      = "vault"
      image     = "busybox:latest"
      essential = true
      cpu       = 50
      memory    = 50
      command   = ["/bin/sh -c \"echo '{{FLAG_1234677}}' >  /FLAG.TXT; sleep 365d\""]
      entryPoint = [
        "sh",
        "-c"
      ]
    }
  ])
}

// Hosts the role we want to use to force rescheduling
resource "aws_ecs_task_definition" "privd" {
  family        = "cg-${var.scenario-name}-${var.cgid}-privd"
  task_role_arn = aws_iam_role.privd.arn
  container_definitions = jsonencode([
    {
      name      = "privd"
      image     = "busybox:latest"
      cpu       = 50
      memory    = 50
      essential = true
      command   = ["sleep", "365d"]
    }
  ])
}

// Hosts website to container escape
resource "aws_ecs_task_definition" "vulnsite" {
  family       = "cg-${var.scenario-name}-${var.cgid}-vulnsite"
  network_mode = "host"
  container_definitions = jsonencode([
    {
      name         = "vulnsite"
      image        = "cloudgoat/ecs-takeover-vulnsite:latest"
      essential    = true
      privileged   = true
      network_mode = "awsvpc"
      cpu          = 256
      memory       = 256
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      mountPoints = [
        {
          readOnly      = false,
          containerPath = "/var/run/docker.sock"
          sourceVolume  = "docker-socket"
        }
      ]
    }
  ])

  volume {
    name      = "docker-socket"
    host_path = "/var/run/docker.sock"
  }
}


resource "aws_ecs_service" "vulnsite" {
  name            = "vulnsite"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.vulnsite.arn
  desired_count   = 1

  placement_constraints {
    type       = "memberOf"
    expression = "ec2InstanceId == ${aws_instance.vulnsite.id}"
  }
}

resource "aws_ecs_service" "privd" {
  name                 = "privd"
  cluster              = aws_ecs_cluster.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.privd.arn
  force_new_deployment = true
  scheduling_strategy  = "DAEMON"
  desired_count        = 2
}


resource "aws_ecs_service" "vault" {
  name                 = "vault"
  cluster              = aws_ecs_cluster.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.vault.arn
  force_new_deployment = true
  desired_count        = 1


  depends_on = [
    aws_ecs_service.vulnsite,
  ]

  ordered_placement_strategy {
    type = "random"
  }

  // Setting this here ensures vault start's on the right instance, this setting is removed in the provisioner below.
  placement_constraints {
    type       = "memberOf"
    expression = "ec2InstanceId == ${aws_instance.vault.id}"
  }

  provisioner "local-exec" {
    command = "/usr/bin/env python3 remove_placement_constraints.py"
    environment = {
      CLUSTER            = self.cluster
      SERVICE_NAME       = self.name
      AWS_DEFAULT_REGION = var.region
      AWS_PROFILE        = var.profile
    }
  }
}
