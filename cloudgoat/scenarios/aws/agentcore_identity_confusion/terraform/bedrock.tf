locals {
  bedrock_model_arn     = "arn:aws:bedrock:${var.region}::foundation-model/${var.kb_model_id}"
}

#############################
# Knowledgebase Role
#############################
resource "aws_iam_role" "kb_role" {
  name = "kb_role_${var.cgid}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.aws-account-id.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.aws-account-id.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "kb_role_policy" {
  name = "kb_role_policy_${var.cgid}"
  role = aws_iam_role.kb_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = local.bedrock_model_arn
      },
      {
        Sid      = "S3ListBucketStatement"
        Action   = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.kb_s3_bucket.arn,
          "${aws_s3_bucket.kb_s3_bucket.arn}/*"
        ]
      },
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.kb_oss_collection.arn
      }
    ]
  })
}

resource "time_sleep" "kb_role_policy_sleep" {
  create_duration = "20s"
  depends_on      = [aws_iam_role_policy.kb_role_policy]
}

#############################
# Knowledgebase
#############################
resource "aws_bedrockagent_knowledge_base" "kb" {
  name     = "kb-${var.cgid}"
  role_arn = aws_iam_role.kb_role.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = local.bedrock_model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb_oss_collection.arn
      vector_index_name = opensearch_index.kb_oss_index.name
      field_mapping {
        vector_field   = "kb-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [
    opensearch_index.kb_oss_index,
    time_sleep.kb_role_policy_sleep
  ]
}

resource "aws_bedrockagent_data_source" "kb_data_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.kb.id
  name              = "kb-datasource-${var.cgid}"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.kb_s3_bucket.arn
    }
  }
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 512
        overlap_percentage = 20
      }
    }
  }
}

resource "terraform_data" "kb_ingestion" {
  depends_on = [ aws_bedrockagent_data_source.kb_data_source ]

  triggers_replace = {
    kb_id    = aws_bedrockagent_knowledge_base.kb.id
    kb_ds_id = aws_bedrockagent_data_source.kb_data_source.data_source_id
  }

  provisioner "local-exec" {
    when       = create
    on_failure = fail
    command    = "aws bedrock-agent start-ingestion-job --knowledge-base-id ${self.triggers_replace.kb_id} --data-source-id ${self.triggers_replace.kb_ds_id} --region ${var.region} --profile ${var.profile}"
  }
}
