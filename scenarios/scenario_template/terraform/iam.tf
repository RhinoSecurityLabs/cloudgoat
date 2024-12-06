# Role for EC2
resource "aws_iam_role" "cg-ec2-role" {
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
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Role Policy for EC2
resource "aws_iam_role_policy" "cg-ec2-policy" {
  name   = "cg-ec2-policy-${var.cgid}"
  role   = aws_iam_role.cg-ec2-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Attach the EC2 Role to an Instance Profile
resource "aws_iam_instance_profile" "cg-ec2-instance-profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.cg-ec2-role.name
}

# Sample User 1
resource "aws_iam_user" "cg-user1" {
  name = "cg-user1-${var.cgid}"
  tags = {
    Name = "cg-user1-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_user_policy" "cg-user1-policy" {
  name = "cg-user1-policy-${var.cgid}"
  user = aws_iam_user.cg-user1.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "cg-user1-key" {
  user = aws_iam_user.cg-user1.name
}

# Sample User 2
resource "aws_iam_user" "cg-user2" {
  name = "cg-user2-${var.cgid}"
  tags = {
    Name = "cg-user2-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_user_policy" "cg-user2-policy" {
  name = "cg-user2-policy-${var.cgid}"
  user = aws_iam_user.cg-user2.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:ListTables",
        "dynamodb:DescribeTable"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "cg-user2-key" {
  user = aws_iam_user.cg-user2.name
}
