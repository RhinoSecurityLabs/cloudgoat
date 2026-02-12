resource "aws_opensearchserverless_access_policy" "kb_oss_collection_policy" {
  name = "oss-access-${var.cgid}"
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/kb-oss-collection-${var.cgid}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/kb-oss-collection-${var.cgid}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        aws_iam_role.kb_role.arn,
        data.aws_caller_identity.aws-account-id.arn
      ]
    }
  ])
}

# OpenSearch collection data encryption policy
resource "aws_opensearchserverless_security_policy" "kb_oss_encryption_policy" {
  name = "oss-encryption-${var.cgid}"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/kb-oss-collection-${var.cgid}"
        ]
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

# OpenSearch collection network policy
resource "aws_opensearchserverless_security_policy" "kb_oss_network_policy" {
  name = "oss-network-${var.cgid}"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/kb-oss-collection-${var.cgid}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/kb-oss-collection-${var.cgid}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch resource
resource "aws_opensearchserverless_collection" "kb_oss_collection" {
  name = "kb-oss-collection-${var.cgid}"
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_access_policy.kb_oss_collection_policy,
    aws_opensearchserverless_security_policy.kb_oss_encryption_policy,
    aws_opensearchserverless_security_policy.kb_oss_network_policy
  ]
}

# Creating the index *immediately* after the collection sometimes fails on permissions errors.
# The access policy needs a few seconds to get recognized.
resource "time_sleep" "kb_oss_collection_sleep" {
  create_duration = "20s"
  depends_on      = [aws_opensearchserverless_collection.kb_oss_collection]
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.kb_oss_collection.collection_endpoint
  healthcheck = false
  aws_profile = var.profile
}

# OpenSearch index creation
resource "opensearch_index" "kb_oss_index" {
  name                           = "kb-index-${var.cgid}"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "kb-vector": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [time_sleep.kb_oss_collection_sleep]
}
