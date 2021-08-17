#IAM User
resource "aws_iam_user" "bilbo" {
  name = "bilbo-${var.cgid}"
  tags = {
    Name     = "cg-chris-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_access_key" "bilbo" {
  user = aws_iam_user.bilbo.name
}

# IAM roles
resource "aws_iam_role" "cg-lambdaInvoker-role" {
  name = "cg-lambdaManager-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${aws_iam_user.bilbo.arn}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "cg-debug-role-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}