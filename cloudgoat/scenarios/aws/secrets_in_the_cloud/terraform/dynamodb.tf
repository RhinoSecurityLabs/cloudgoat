# This is a Terraform file that creates three resources:
# 1. An AWS DynamoDB Table
# 2. An AWS DynamoDB Entry (for the Access ID)
# 3. An AWS DynamoDB Entry (for the Secret Key)

resource "aws_dynamodb_table" "secrets_table" {
  name         = "secrets-table-${local.cgid_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }

  # Enable server-side encryption using the default AWS KMS key
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "secrets_table"
  }
}

resource "aws_dynamodb_table_item" "access_key_id" {
  table_name = aws_dynamodb_table.secrets_table.name
  hash_key   = aws_dynamodb_table.secrets_table.hash_key

  item = jsonencode({
    key = {
      S = "secrets_manager_user_key_id"
    }
    value = {
      S = aws_iam_access_key.secrets_manager_user_key.id
    }
  })
}

resource "aws_dynamodb_table_item" "secret_access_key" {
  table_name = aws_dynamodb_table.secrets_table.name
  hash_key   = aws_dynamodb_table.secrets_table.hash_key

  item = jsonencode({
    key = {
      S = "secrets_manager_user_key_secret"
    }
    value = {
      S = aws_iam_access_key.secrets_manager_user_key.secret
    }
  })
}
