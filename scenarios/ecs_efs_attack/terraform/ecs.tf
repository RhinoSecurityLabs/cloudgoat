resource "aws_ecs_cluster" "cg-devops-cluster" {
    name = "cg-devops-cluster-${var.cgid}"
}


resource "aws_ecs_task_definition" "webapp" {
  family = "webapp"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn = "${aws_iam_role.cg-ecs-role.arn}"
  execution_role_arn = "${aws_iam_role.cg-ecs-role.arn}"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "environment": [{
      "name": "SECRET",
      "value": "KEY"
    }],

    "command": [
            "/bin/sh -c \"echo '<html> <head> <title>CloudGoat EC2 </title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>CloudGoat ...</h1> <h2>Congratulations!</h2> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
         ],
         "entryPoint": [
            "sh",
            "-c"
         ],
    "essential": true,
    "image": "httpd:2.4",
    "memory": 128,
    "memoryReservation": 64,
    "name": "webapp",
    "portMappings": [ 
            { 
               "containerPort": 80,
               "hostPort": 80,
               "protocol": "tcp"
            }
         ]
  }
]
DEFINITION
}


data "aws_ecs_task_definition" "webapp" {
  task_definition = "${aws_ecs_task_definition.webapp.family}"
}

resource "aws_ecs_service" "webapp" {
  name          = "webapp"
  cluster       = "${aws_ecs_cluster.cg-devops-cluster.name}"
  desired_count = 1
  launch_type   = "FARGATE"

 network_configuration  {
    security_groups = [aws_security_group.cg-ecs-http-security-group.id]
    subnets         = ["${aws_subnet.cg-public-subnet-1.id}"]
    assign_public_ip = true
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.webapp.family}:${max("${aws_ecs_task_definition.webapp.revision}", "${data.aws_ecs_task_definition.webapp.revision}")}"
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
            "Sid": "ec2Perms",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances", 
                "ec2:DescribeImages",
                "ec2:DescribeTags", 
                "ec2:DescribeSnapshots",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        
         {
            "Sid": "startSession",
            "Effect": "Allow",
            "Action": [
              "ssm:StartSession"
            ],
            "Resource": "*",
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


resource "aws_security_group" "cg-ecs-http-security-group" {
  name = "cg-ecs-http-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for ecs"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = var.cg_whitelist
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "cg-ecs-http-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}