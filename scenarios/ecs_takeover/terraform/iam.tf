//
// ECS Worker Instance Role
//
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "cg-${var.scenario-name}-${var.cgid}-ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "cg-${var.scenario-name}-${var.cgid}-ecs-agent"
  role = aws_iam_role.ecs_agent.name
}



//
//  ECS Container role
//

data "aws_iam_policy_document" "ecs_tasks_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}



resource "aws_iam_role" "privd" {
  name                = "cg-${var.scenario-name}-${var.cgid}-privd"
  assume_role_policy  = data.aws_iam_policy_document.ecs_tasks_role.json
  managed_policy_arns = [aws_iam_policy.privd.arn]
}

// Give the role read access to ecs and IAM permissions.
resource "aws_iam_policy" "privd" {
  name = "cg-${var.scenario-name}-${var.cgid}-privd"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:ListServices",
          "ecs:ListTasks",
          "ecs:DescribeServices",
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTasks",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeClusters",
          "ecs:ListClusters",
          "iam:GetPolicyVersion",
          "iam:GetPolicy",
          "iam:ListAttachedRolePolicies",
          "iam:GetRolePolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}