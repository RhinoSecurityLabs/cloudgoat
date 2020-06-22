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
#    task_role_arn = aws_iam_role.cg-ecs-role.arn
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



#IAM Role
resource "aws_iam_role" "cg-ecs-role" {
  name = "cg-ecs-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "cg-ecs-role-${var.cgid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Iam Role Policy
resource "aws_iam_policy" "cg-ecs-role-policy" {
  name = "cg-ecs-role-policy-${var.cgid}"
  description = "cg-ecs-role-policy-${var.cgid}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "tagStartSession",
            "Effect": "Allow",
            "Action": [
                "ec2:ssm:StartSession",
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
              "StringEquals": {
                "aws:RequestTag/StartSession": "true"
              }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "cg-ecs-role-policy-attachment" {
  name = "cg-ecs-role-policy-attachment-${var.cgid}"
  roles = [
      "${aws_iam_role.cg-ecs-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cg-ecs-role-policy.arn}"
}
