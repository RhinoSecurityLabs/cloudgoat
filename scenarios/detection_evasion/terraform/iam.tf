#IAM Users and Keys
resource "aws_iam_user" "r_waterhouse" {
  name = "r_waterhouse"
  path = "/"
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_iam_access_key" "r_waterhouse" {
  user = aws_iam_user.r_waterhouse.name
}

resource "aws_iam_user" "canarytoken_user" {
  name = "canarytokens.com@@kz9r8ouqnhve4zs1yi4bzspzz"
  path = "/"
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_iam_access_key" "canarytoken_user" {
  user = aws_iam_user.canarytoken_user.name
}

resource "aws_iam_user" "spacecrab_user" {
  name = "l_salander"
  path = "/SpaceCrab/"
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_iam_access_key" "spacecrab_user" {
  user = aws_iam_user.spacecrab_user.name
}

resource "aws_iam_user" "spacesiren_user" {
  name = "cd1fceca-e751-4c1b-83e4-78d309063830"
  path = "/"
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_iam_access_key" "spacesiren_user" {
  user = aws_iam_user.spacesiren_user.name
}

#IAM Groups and Members
resource "aws_iam_group" "developers" {
  name = "cg-developers"
  path = "/developers/"
}

resource "aws_iam_group_membership" "dev_team" {
  name = "developer_group_membership"
  users = [
    aws_iam_user.r_waterhouse.name,
  ]
  group = aws_iam_group.developers.name
}

resource "aws_iam_group_policy_attachment" "test-attach" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}


resource "aws_iam_group_policy" "developer_policy" {
  name  = "developer_policy"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:ResumeSession",
          "ssm:TerminateSession",
          "ssm:StartSession"
        ]
        Resource = [
          "arn:aws:ssm:*:*:patchbaseline/*",
          "arn:aws:ssm:*:*:managed-instance/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ssm:*:*:session/*",
          "arn:aws:ssm:*:*:document/*"
        ]
      },
    ]
  })
}


# instance profile for the easy path
resource "aws_iam_instance_profile" "ec2_instance_profile_easy_path" {
  name = "${var.cgid}_easy"
  role = aws_iam_role.ec2_instance_profile_role_easy_path.name
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_iam_role" "ec2_instance_profile_role_easy_path" {
  name = "${var.cgid}_easy"
  path = "/"
  tags = {
    tag-key = var.cgid
  }
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
}

resource "aws_iam_role_policy_attachment" "ssm_policy_core_easy_path" {
  role       = aws_iam_role.ec2_instance_profile_role_easy_path.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_easy_path" {
  role       = aws_iam_role.ec2_instance_profile_role_easy_path.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "instance_profile_easy_path" {
  name = "cg_instance_profile_policy_easy_path"
  role = aws_iam_role.ec2_instance_profile_role_easy_path.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
        ],
        "Resource" : aws_secretsmanager_secret.easy_secret.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        "Resource" : "*"
      }
    ]
  })
}

// instance profile for the hard path
resource "aws_iam_instance_profile" "ec2_instance_profile_hard_path" {
  name = "${var.cgid}_hard"
  role = aws_iam_role.ec2_instance_profile_role_hard_path.name
  tags = {
    tag-key = var.cgid
  }
}

resource "aws_iam_role" "ec2_instance_profile_role_hard_path" {
  name = "${var.cgid}_hard"
  path = "/"
  tags = {
    tag-key = var.cgid
  }
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
}

resource "aws_iam_role_policy_attachment" "ssm_policy_core_hard_path" {
  role       = aws_iam_role.ec2_instance_profile_role_hard_path.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_hard_path" {
  role       = aws_iam_role.ec2_instance_profile_role_hard_path.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_iam_role_policy" "instance_profile_hard_path" {
  name = "cg_instance_profile_policy_hard_path"
  role = aws_iam_role.ec2_instance_profile_role_hard_path.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
        ],
        "Resource" : aws_secretsmanager_secret.hard_secret.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        "Resource" : "*"
      }
    ]
  })
}