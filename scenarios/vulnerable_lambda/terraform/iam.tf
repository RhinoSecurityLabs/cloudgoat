#IAM User
resource "aws_iam_user" "bilbo" {
  name          = "cg-bilbo-${var.cgid}"
  force_destroy = true

  tags = {
    deployment_profile = var.profile
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name} ${self.tags.deployment_profile}"
  }
}

resource "aws_iam_access_key" "bilbo" {
  user = aws_iam_user.bilbo.name
}

resource "aws_iam_user_policy" "standard_user" {
  name = "${aws_iam_user.bilbo.name}-standard-user-assumer"
  user = aws_iam_user.bilbo.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = ""
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::940877411605:role/cg-lambda-invoker*"
      },
      {
        Sid    = ""
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*",
          "iam:SimulateCustomPolicy",
          "iam:SimulatePrincipalPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cg-lambda-invoker" {
  name = "cg-lambda-invoker-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_user.bilbo.arn
        }
      }
    ]
  })

  inline_policy {
    name = "lambda-invoker"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "lambda:ListFunctionEventInvokeConfigs",
            "lambda:InvokeFunction",
            "lambda:ListTags",
            "lambda:GetFunction",
            "lambda:GetPolicy"
          ]
          Resource = aws_lambda_function.policy_applier_lambda1.arn
        },
        {
          Effect = "Allow"
          Action = [
            "lambda:ListFunctions",
            "iam:Get*",
            "iam:List*",
            "iam:SimulateCustomPolicy",
            "iam:SimulatePrincipalPolicy"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
