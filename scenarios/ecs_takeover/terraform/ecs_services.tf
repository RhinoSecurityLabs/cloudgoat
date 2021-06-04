
resource "aws_ecs_task_definition" "vault" {
  family = "vault"
  depends_on = [aws_ecs_service.vulnsite, aws_ecs_service.privd]

  # Wait for the website to be deployed to the cluster. 
  # This should make sure the instances are avaible. 
  container_definitions = jsonencode([
    {
      name      = "vault"
      image     = "busybox:latest"
      cpu       = 2
      memory    = 50
      essential = true
      command = ["/bin/sh -c \"echo '{{FLAG_1234678}}' >  /FLAG.TXT; sleep 3600\""]
      "entryPoint" = [
            "sh",
            "-c"
         ]
    }
  ])


    provisioner "local-exec" {
        command = "/bin/bash vaultdeploy.sh"
        environment = {
          CLUSTERNAME = aws_ecs_cluster.ecs_cluster.id
          TASK = aws_ecs_task_definition.vault.arn
          WEBSITE =   aws_ecs_service.vulnsite.name
          AWS_DEFAULT_REGION = var.region
        }
    }
}

// Hosts role we want to use to force reshced
resource "aws_ecs_task_definition" "privd" {
  family = "privd"
  task_role_arn = aws_iam_role.containerRole.arn
  container_definitions = jsonencode([
    {
      name      = "privd"
      image     = "busybox:latest"
      cpu       = 1
      memory    = 256
      essential = true
      command = ["sleep", "3600"]
    }
  ])
}

// Hosts website to container escape
resource "aws_ecs_task_definition" "vulnsite" {
  family = "vulnsite"
  network_mode = "awsvpc"
  container_definitions = jsonencode([
    {
      name      = "vulnsite"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      cpu       = 1
      memory    = 256
      essential = true
      privileged = true
      network_mode = "awsvpc"
      portMappings = [
        {
          containerPort = 80
        }
      ]
      mountPoints = [
          {
              readOnly = false,
              containerPath = "/var/run/docker.sock"
              sourceVolume = "docker-socket"
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

  network_configuration {
    subnets = [aws_subnet.priv_subnet.id]
    security_groups = [aws_security_group.alb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.website-tg.arn
    container_name = aws_ecs_task_definition.vulnsite.family
    container_port = 80
  }
}

resource "aws_ecs_service" "privd" {
  name            = "privd"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.privd.arn
  desired_count   = 2
}