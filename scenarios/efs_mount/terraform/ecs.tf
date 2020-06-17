resource "aws_ecs_cluster" "cg-devops-cluster" {
    name = "cg-devops-cluster-${var.cgid}"
}


resource "aws_ecs_task_definition" "mongo" {
  family = "mongodb"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "environment": [{
      "name": "SECRET",
      "value": "KEY"
    }],
    "essential": true,
    "image": "mongo:latest",
    "memory": 128,
    "memoryReservation": 64,
    "name": "mongodb"
  }
]
DEFINITION
}


data "aws_ecs_task_definition" "mongo" {
  task_definition = "${aws_ecs_task_definition.mongo.family}"
}

resource "aws_ecs_service" "mongo" {
  name          = "mongo"
  cluster       = "${aws_ecs_cluster.cg-devops-cluster.name}"
  desired_count = 1
  launch_type     = "FARGATE"

 network_configuration  {
    security_groups = [aws_security_group.cg-ec2-ssh-security-group.id]
    subnets         = ["${aws_subnet.cg-public-subnet-1.id}"]
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.mongo.family}:${max("${aws_ecs_task_definition.mongo.revision}", "${data.aws_ecs_task_definition.mongo.revision}")}"
}

