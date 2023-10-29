# Define IAM role for EC2 Instance.
# Assume that excessive privileges are set for this role.
# ec2_role & ec2_role_sub are twin role for renewing credentials.
# Once lambda run, ec2's role would be change to another, and credential's will be renewed.
resource "aws_iam_role" "ec2_role" {
  name = "cg-web-developer-${var.cgid}"
  tags = {
    deployment_profile = var.profile
    Stack              = var.stack-name
    Scenario           = var.scenario-name
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    aws_iam_policy.cg_web_developer_policy.arn
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}

# Define IAM role for EC2 Instance.
# Assume that excessive privileges are set for this role.
resource "aws_iam_role" "ec2_role_sub" {
  name = "cg-web-developer-sub-${var.cgid}"
  tags = {
    deployment_profile = var.profile
    Stack              = var.stack-name
    Scenario           = var.scenario-name
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    aws_iam_policy.cg_web_developer_policy.arn
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}

# Target of Privesc.
# Using PassRole, ECS
resource "aws_iam_role" "s3_access" {
  name = "cg-s3-access-role-${var.cgid}"
  tags = {
    deployment_profile = var.profile
    Stack              = var.stack-name
    Scenario           = var.scenario-name
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}

# Define Lambda's role for sending mail if GuardDuty detects an attack.
# The mail will be sent with SES.
resource "aws_iam_role" "lambda_role" {
  name = "cg-lambda-role-${var.cgid}"
  tags = {
    deployment_profile = var.profile
    Stack              = var.stack-name
    Scenario           = var.scenario-name
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSESFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "cg-lambda-inline-policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Action   = [
            "iam:DetachRolePolicy",
            "iam:AttachRolePolicy",
            "iam:ListAttachedRolePolicies",
            "iam:GetRole",
            "iam:PassRole",
            "iam:ListAttachedRolePolicies",
            "iam:ListRolePolicies",
            "iam:GetRolePolicy",
            "iam:PutRolePolicy",
            "iam:DeleteRolePolicy"
          ],
          Resource = [
            aws_iam_role.ec2_role.arn,
            aws_iam_role.ec2_role_sub.arn
          ]
        },{
          Effect   = "Allow",
          Action   = [
            "guardduty:ListFindings",
            "guardduty:UpdateFindingsFeedback",
            "ec2:DescribeIamInstanceProfileAssociations",
            "ec2:ReplaceIamInstanceProfileAssociation"
          ],
          Resource = "*"
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cg_web_developer_policy" {
  name   = "cg-web-developer-policy-${var.cgid}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "VisualEditor0",
        Effect    = "Allow",
        Resource  = "*",
        Action    = [
          "iam:PassRole",
          "iam:Get*",
          "ec2:DescribeInstances",
          "iam:List*",
          "ecs:RunTask",
          "ecs:Describe*",
          "ecs:RegisterTaskDefinition",
          "ec2:DescribeSubnets",
          "ecs:List*",
          "s3:*"
        ]
      }
    ]
  })
}

# Getting instance profile for lambda
resource "aws_iam_instance_profile" "instance_profile_1" {
  name = "cg-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "instance_profile_2" {
  name = "cg-instance-profile-sub-${var.cgid}"
  role = aws_iam_role.ec2_role_sub.name
}