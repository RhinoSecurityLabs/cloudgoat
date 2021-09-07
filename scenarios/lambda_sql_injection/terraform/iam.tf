#IAM User
resource "aws_iam_user" "bilbo" {
  name = "cg-bilbo-${var.cgid}"
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_access_key" "bilbo" {
  user = aws_iam_user.bilbo.name
}

resource "aws_iam_user_policy" "standard_user" {
  name = "cg-${aws_iam_user.bilbo.name}-standard-user-assumer"
  user = aws_iam_user.bilbo.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::940877411605:role/standard-user*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "standard-user-lambda-invoker" {
  name = "standard-user-cg-${var.cgid}"
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "lambda:ListFunctionEventInvokeConfigs",
            "lambda:InvokeFunction",
            "lambda:ListTags",
            "lambda:GetFunction",
            "lambda:GetPolicy"
            ]
          Effect   = "Allow"
          Resource = "${aws_lambda_function.role_creator_lambda.arn}"
        },
        {
          Action   = ["lambda:ListFunctions"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "AWS": [
            "${aws_iam_user.bilbo.arn}"
          ]
        }
      },
    ]
  })
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_role" "super-user-lambda-invoker" {
  name = "super-user-cg-${var.cgid}"
  inline_policy {
    name = "my_inline_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "lambda:ListFunctionEventInvokeConfigs",
            "lambda:InvokeFunction",
            "lambda:ListTags",
            "lambda:GetFunction",
            "lambda:GetPolicy"
            ]
          Effect   = "Allow"
          Resource = "${aws_lambda_function.role_creator_lambda.arn}"
        },
        {
          Action   = [
            "lambda:ListFunctions",
            "lambda:InvokeFunction"
            ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "Service": "lambda.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "cd-${var.cgid}-iam_for_lambda"
  inline_policy {
    name = "my_inline_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "iam:AttachUserPolicy"
          Effect   = "Allow"
          Resource = "${aws_iam_user.bilbo.arn}"
        },
        {
          Action   = "s3:GetObject"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}


