#IAM Users and Keys
resource "aws_iam_user" "r_waterhouse" {
  name = "r_waterhousey"
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

resource "aws_iam_user" "c_english" {
  name = "c_english"
  path = "/Canary/"
  tags = {
    tag-key = "${var.cgid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "c_english" {
  user = aws_iam_user.c_english.name
}

resource "aws_iam_user" "l_salander" {
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

resource "aws_iam_access_key" "l_salander" {
  user = aws_iam_user.l_salander.name
}

resource "aws_iam_user" "s_cylander" {
  name = "s_cylander"
  path = "/SpaceSiren/"
  tags = {
    tag-key = "${var.cgid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "s_cylander" {
  user = aws_iam_user.s_cylander.name
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
    aws_iam_user.c_english.name,
    aws_iam_user.l_salander.name,
    aws_iam_user.s_cylander.name,
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

