
###########  EC2 Roles ###############
resource "aws_iam_role" "cg-ecsTaskExecutionRole-role" {
  name = "cg-ec2-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "cg-ec2-role-${var.cgid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}


#IAM Admin Role

resource "aws_iam_role" "cg-efs-admin-role" {
  name = "cg-efs-admin-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "cg-ec2-efsUser-role-${var.cgid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}

#Iam Role Policy
resource "aws_iam_policy" "cg-ecsTaskExecutionRole-ruse-role-policy" {
  name = "cg-ecsTaskExecutionRole-ruse-role-policy-${var.cgid}"
  description = "cg-ecsTaskExecutionRole-ruse-role-policy-${var.cgid}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "ecs:Describe*",
              "ecs:List*",
              "ecs:RegisterTaskDefinition",
              "ecs:UpdateService",
              "iam:PassRole",
              "ec2:CreateTags",
              "ec2:DescribeInstances", 
              "ec2:DescribeImages",
              "ec2:DescribeTags", 
              "ec2:DescribeSnapshots"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_policy" "cg-efs-admin-role-policy" {
  name = "cg-efs-admin-role-policy-${var.cgid}"
  description = "cg-efs-admin-role-policy-${var.cgid}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "elasticfilesystem:ClientMount"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}


################### ECS #####################



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
              "ssm:SendCommand",
                "ssm:ResumeSession",
                "ssm:ListTagsForResource",
                "ssm:TerminateSession",
                "ssm:StartSession"
            ],
            "Condition": {
              "StringEquals": {
                "aws:ResourceTag/StartSession": "true"
              }
            },
            "Resource": "*"
        }
    ]
}
POLICY
}


            