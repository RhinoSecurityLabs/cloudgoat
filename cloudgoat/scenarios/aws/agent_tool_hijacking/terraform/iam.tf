#############################
# Starting User (Initial Credentials)
#############################

resource "aws_iam_user" "starting_user" {
  name = "grace_${var.cgid}"
}

resource "aws_iam_access_key" "starting_user_key" {
  user = aws_iam_user.starting_user.name
}

# Iam enumeration is not part of the challenge. Might as well make it easy
resource "aws_iam_user_policy_attachment" "starting_user_iam_policy_attachment" {
  user       = aws_iam_user.starting_user.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_policy" "starting_user_bedrock_policy" {
  name = "agent_access_policy_${var.cgid}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "BedrockReadOnly"
        Effect = "Allow"
        Action = [
          "bedrock:Get*",
          "bedrock:List*"
        ],
        Resource = "*"
      },
      {
        Sid    = "InvokeOperationsAgent"
        Effect = "Allow",
        Action = [
          "bedrock:InvokeAgent"
        ],
        Resource = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.aws-account-id.account_id}:agent-alias/${aws_bedrockagent_agent.operations_agent.agent_id}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "starting_user_bedrock_policy_attachment" {
  user       = aws_iam_user.starting_user.name
  policy_arn = aws_iam_policy.starting_user_bedrock_policy.arn
}

resource "aws_iam_policy" "starting_user_deployment_policy" {
  name = "lambda_deployment_policy_${var.cgid}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LambdaUpdateAccess"
        Effect = "Allow",
        Action = [
          "lambda:CreateAlias",
          "lambda:GetAlias",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:ListAliases",
          "lambda:ListVersionsByFunction",
          "lambda:PublishVersion",
          "lambda:UpdateAlias",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "starting_user_deployment_policy_attachment" {
  user       = aws_iam_user.starting_user.name
  policy_arn = aws_iam_policy.starting_user_deployment_policy.arn
}
