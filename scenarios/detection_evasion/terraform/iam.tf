#IAM Users and Keys
resource "aws_iam_user" "r_waterhouse" {
  name = "r_waterhouse"
  path = "/"
  tags = {
    tag-key = "${var.cgid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "r_waterhouse" {
  user = aws_iam_user.r_waterhouse.name
}

resource "aws_iam_user" "canarytoken_user" {
  name = "canarytokens.com@@kz9r8ouqnhve4zs1yi4bzspzz"
  path = "/"
  tags = {
    tag-key = "${var.cgid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "canarytoken_user" {
  user = aws_iam_user.canarytoken_user.name
}

resource "aws_iam_user" "spacecrab_user" {
  name = "l_salander"
  path = "/SpaceCrab/"
  tags = {
    tag-key = "${var.cgid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "spacecrab_user" {
  user = aws_iam_user.spacecrab_user.name
}

resource "aws_iam_user" "spacesiren_user" {
  name = "cd1fceca-e751-4c1b-83e4-78d309063830"
  path = "/"
  tags = {
    tag-key = "${var.cgid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "spacesiren_user" {
  user = aws_iam_user.spacesiren_user.name
}

#IAM Groups and Members
resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/developers/"
  
}

resource "aws_iam_group_membership" "dev_team" {
  name = "developer_group_membership"

  users = [
    aws_iam_user.r_waterhouse.name,
    aws_iam_user.canarytoken_user.name,
    aws_iam_user.spacecrab_user.name,
    aws_iam_user.spacesiren_user.name,
  ]

  group = aws_iam_group.developers.name
}

resource "aws_iam_group_policy" "developer_policy" {
  name  = "developer_policy"
  group = aws_iam_group.developers.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:DescribeInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:ResumeSession",
          "ssm:TerminateSession",
          "ssm:DeletePatchBaseline",
          "ssm:DeleteParameters",
          "ssm:StartSession"
        ]
        Resource = [
            "arn:aws:ecs:*:*:task/*",
            "arn:aws:ssm:*:*:patchbaseline/*",
            "arn:aws:s3:::*",
            "arn:aws:ssm:*:*:managed-instance/*",
            "arn:aws:ssm:*:*:parameter/*",
            "arn:aws:ec2:*:*:instance/*",
            "arn:aws:ssm:*:*:session/*",
            "arn:aws:ssm:*:*:document/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "ssm:CancelCommand"
        Resource = "*"
      }
    ]
  })
}


# instance profile for the first target ec2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile_"
  role = aws_iam_role.ec2_instance_profile_role.name
  tags = {
    tag-key = "${var.cgid}"
  }
}

resource "aws_iam_role" "ec2_instance_profile_role" {
  name = "ec2_instance_profile_role_"
  path = "/"
  tags = {
    tag-key = "${var.cgid}"
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

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_policy_core" {
  role       = aws_iam_role.ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


// resource "aws_iam_role_policy" "instance_profile" {
//   name = "instance_profile_policy"
//   role = aws_iam_role.ec2_instance_profile.id
//   policy = jsonencode({
//     Version = "2012-10-17"
//     Statement = [
//       {
//         Action = [
//           "ec2:Describe*",
//         ]
//         Effect   = "Allow"
//         Resource = "*"
//       },
//     ]
//   })
// }