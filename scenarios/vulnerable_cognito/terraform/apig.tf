# Create S3 Full Access Policy
resource "aws_iam_policy" "s3_policy" {
  name        = "s3-policy${var.cgid}"
  description = "Policy for allowing all S3 Actions"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "s3:Get*"
          Resource = "${aws_s3_bucket.cognito_s3.arn}/*"
        }
      ]
    }
  )
}

# Create API Gateway Role
resource "aws_iam_role" "s3_api_gateyway_role" {
  name = "s3-api-gateyway-role-${var.cgid}"

  # Create Trust Policy for API Gateway
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = ""
          Effect = "Allow"
          Principal = {
            Service = "apigateway.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ]
    }
  )
}

# Attach S3 Access Policy to the API Gateway Role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.s3_api_gateyway_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_api_gateway_rest_api" "MyS3" {
  name        = "VulnerableCognito"
  description = "API for S3 Integration"
}

resource "aws_api_gateway_resource" "Folder" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  parent_id   = aws_api_gateway_rest_api.MyS3.root_resource_id
  path_part   = "{folder}"
}

resource "aws_api_gateway_resource" "Item" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  parent_id   = aws_api_gateway_resource.Folder.id
  path_part   = "{item}"
}

resource "aws_api_gateway_method" "GetBuckets" {
  rest_api_id   = aws_api_gateway_rest_api.MyS3.id
  resource_id   = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "GetBucketFolder" {
  rest_api_id   = aws_api_gateway_rest_api.MyS3.id
  resource_id   = aws_api_gateway_resource.Folder.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.folder" = true
  }
}

resource "aws_api_gateway_method" "GetBucketItem" {
  rest_api_id   = aws_api_gateway_rest_api.MyS3.id
  resource_id   = aws_api_gateway_resource.Item.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.item"   = true
    "method.request.path.folder" = true
  }
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "GET"

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path//"
  credentials = aws_iam_role.s3_api_gateyway_role.arn
}

resource "aws_api_gateway_integration" "S3FolderIntegration" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Folder.id
  http_method = aws_api_gateway_method.GetBucketFolder.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "GET"

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path/{bucket}"
  credentials = aws_iam_role.s3_api_gateyway_role.arn

  request_parameters = {
    "integration.request.path.bucket" = "method.request.path.folder"
  }

  passthrough_behavior = "WHEN_NO_MATCH"

}

resource "aws_api_gateway_integration" "S3ItemIntegration" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetBucketItem.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "GET"

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path/{bucket}/{object}"
  credentials = aws_iam_role.s3_api_gateyway_role.arn
  request_parameters = {
    "integration.request.path.bucket" = "method.request.path.folder"
    "integration.request.path.object" = "method.request.path.item"
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "two00" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp"      = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type"   = true
  }
}

resource "aws_api_gateway_method_response" "four00" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "five00" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "two00IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method
  status_code = aws_api_gateway_method_response.two00.status_code

  response_parameters = {
    "method.response.header.Timestamp"      = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_method_response" "two00Folder" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Folder.id
  http_method = aws_api_gateway_method.GetBucketFolder.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp"      = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type"   = true
  }
}

resource "aws_api_gateway_integration_response" "two00FolderIntegrationResponse" {
  depends_on  = [aws_api_gateway_integration.S3FolderIntegration]
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Folder.id
  http_method = aws_api_gateway_method.GetBucketFolder.http_method
  status_code = aws_api_gateway_method_response.two00Folder.status_code

  response_parameters = {
    "method.response.header.Timestamp"      = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_method_response" "two00Item" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetBucketItem.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "two00ItemIntegrationResponse" {
  depends_on  = [aws_api_gateway_integration.S3ItemIntegration]
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetBucketItem.http_method
  status_code = aws_api_gateway_method_response.two00Item.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "four00IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method
  status_code = aws_api_gateway_method_response.four00.status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "five00IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_rest_api.MyS3.root_resource_id
  http_method = aws_api_gateway_method.GetBuckets.http_method
  status_code = aws_api_gateway_method_response.five00.status_code

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_deployment" "S3APIDeployment" {
  depends_on  = [aws_api_gateway_integration.S3Integration, aws_api_gateway_integration.S3FolderIntegration, aws_api_gateway_integration.S3ItemIntegration]
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
}

resource "aws_api_gateway_stage" "S3APIStage" {
  deployment_id = aws_api_gateway_deployment.S3APIDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.MyS3.id
  stage_name    = "vulncognito"
}

resource "aws_api_gateway_rest_api_policy" "test" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            AWS = "*"
          }
          Action   = "execute-api:Invoke"
          Resource = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.aws-account-id.account_id}:${aws_api_gateway_rest_api.MyS3.id}/*"
        }
      ]
    }
  )
}
