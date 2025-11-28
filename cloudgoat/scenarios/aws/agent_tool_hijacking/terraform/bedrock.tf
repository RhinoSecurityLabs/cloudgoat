resource "aws_iam_role" "bedrock_agent_role" {
  name               = "bedrock_agent_basic_role_${var.cgid}"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_policy" {
  name   = "bedrock_agent_basic_role_policy_${var.cgid}"
  role   = aws_iam_role.bedrock_agent_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:${var.region}::foundation-model/amazon.nova-lite-v1:0"
      }
    ]
  })
}

resource "aws_bedrockagent_agent" "operations_agent" {
  agent_name              = "operations_agent_${var.cgid}"
  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn
  description = "A simple Bedrock Agent that can inventory cloud resources."
  idle_session_ttl_in_seconds = 300

  instruction = <<-EOT
You are a helpful cloud assistant that answers user questions about AWS concisely.
If you don't know the answer, say you don't know rather than making something up.
Use your tools to inventory live cloud resources if required.
EOT

  # Some foundation model providers like anthropic require additional setup. Nova shouldn't
  foundation_model = "amazon.nova-lite-v1:0"
}

resource "aws_bedrockagent_agent_action_group" "inventory_tool" {
  agent_id      = aws_bedrockagent_agent.operations_agent.id
  agent_version = "DRAFT"
  action_group_name = "InventoryTool"
  description = "Action group exposing lambda function that inventories cloud resources"
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = aws_lambda_function.inventory_lambda.arn
  }
  function_schema {
    member_functions {
      functions {
        name        = "LIST_IAM_ROLES"
        description = "Lists up to 100 IAM roles in the current account"
      }
      functions {
        name        = "LIST_IAM_USERS"
        description = "Lists up to 100 IAM users in the current account"
      }
      functions {
        name        = "LIST_EC2_INSTANCES"
        description = "Lists up to 100 EC2 instances in the current account"
      }
      functions {
        name        = "LIST_S3_BUCKETS"
        description = "Lists up to 100 S3 buckets in the current account"
      }
      functions {
        name        = "LIST_ALL"
        description = "Provides a listing of IAM roles, users, EC2 instances, and S3 Buckets in the current account"
      }
    }
  }
}