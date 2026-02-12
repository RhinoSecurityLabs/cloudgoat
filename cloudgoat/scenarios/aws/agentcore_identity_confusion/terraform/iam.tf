#############################
# Code Interpreter Role
#############################
resource "aws_iam_role" "code_interpreter_role" {
  name = "agentcore_code_interpreter_execution_role_${var.cgid}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "code_interpreter_role_policy" {
  role   = aws_iam_role.code_interpreter_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kb_code_interpreter_bucket.arn,
          "${aws_s3_bucket.kb_code_interpreter_bucket.arn}/*"
        ]
      }
    ]
  })
}

#############################
# Agent Runtime Role
#############################
resource "aws_iam_role" "agent_runtime_role" {
  name = "agentcore_agent_runtime_role_${var.cgid}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "agent_runtime_role_policy" {
  role   = aws_iam_role.agent_runtime_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockModelInvocation"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        "Resource": "*"
      },
      {
        Sid    = "CodeInterpreterAccess"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeCodeInterpreter",
          "bedrock-agentcore:StartCodeInterpreterSession",
          "bedrock-agentcore:StopCodeInterpreterSession"
        ]
        "Resource": "*"
      },
      {
        Sid    = "KnowledgeBaseAccess"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        "Resource": aws_bedrockagent_knowledge_base.kb.arn
      }
    ]
  })
}


#############################
# Starting User
#############################
resource "aws_iam_user" "starting_user" {
  name = "sandy_${var.cgid}"
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
          "bedrock:List*",
          "bedrock-agentcore:Get*",
          "bedrock-agentcore:List*"
        ],
        Resource = "*"
      },
      {
        Sid    = "CodeInterpreterManagement"
        Effect = "Allow",
        Action = [
          "bedrock-agentcore:*CodeInterpreter*"
        ],
        Resource = "*"
      },
      {
        Sid    = "CodeInterpreterRoleManagement"
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.aws-account-id.account_id}:role/agentcore_*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "starting_user_bedrock_policy_attachment" {
  user       = aws_iam_user.starting_user.name
  policy_arn = aws_iam_policy.starting_user_bedrock_policy.arn
}
