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
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

