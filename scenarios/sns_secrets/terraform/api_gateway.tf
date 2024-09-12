resource "aws_api_gateway_rest_api" "api" {
  name        = "cg-api-${var.cgid}"
  description = "API for demonstrating leaked API key scenario"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "user-data"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.resource.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code
  response_templates = {
    "application/json" = jsonencode({
      message = "Access granted"
      user_data = {
        user_id  = "1337"
        username = "SuperAdmin"
        email    = "SuperAdmin@notarealemail.com"
        password = "p@ssw0rd123"
      }
      final_flag = "FLAG{SNS_S3cr3ts_ar3_FUN}"
    })
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration_response.integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod-${var.cgid}"
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "cg-usage-plan-${var.cgid}"
  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_deployment.deployment.stage_name
  }
}

resource "aws_api_gateway_api_key" "api_key" {
  name    = "cg-api-key-${var.cgid}"
  enabled = true
  value   = "45a3da610dc64703b10e273a4db135bf"
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
