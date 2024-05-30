resource "aws_api_gateway_rest_api" "cg_api" {
  name        = "cg-api-${var.cgid}"
  description = "API for demonstrating leaked API key scenario"
  tags = {
    Name     = "cg-api-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_api_gateway_resource" "cg_resource" {
  rest_api_id = aws_api_gateway_rest_api.cg_api.id
  parent_id   = aws_api_gateway_rest_api.cg_api.root_resource_id
  path_part   = "resource"
}

resource "aws_api_gateway_method" "cg_method" {
  rest_api_id   = aws_api_gateway_rest_api.cg_api.id
  resource_id   = aws_api_gateway_resource.cg_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "cg_integration" {
  rest_api_id = aws_api_gateway_rest_api.cg_api.id
  resource_id = aws_api_gateway_resource.cg_resource.id
  http_method = aws_api_gateway_method.cg_method.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_deployment" "cg_deployment" {
  depends_on = [aws_api_gateway_integration.cg_integration]
  rest_api_id = aws_api_gateway_rest_api.cg_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_usage_plan" "cg_usage_plan" {
  name = "cg-usage-plan-${var.cgid}"
  api_stages {
    api_id = aws_api_gateway_rest_api.cg_api.id
    stage  = aws_api_gateway_deployment.cg_deployment.stage_name
  }
}

resource "aws_api_gateway_api_key" "cg_api_key" {
  name = "cg-api-key-${var.cgid}"
  enabled = true
  value = "leaked-api-key-value"
}

resource "aws_api_gateway_usage_plan_key" "cg_usage_plan_key" {
  key_id = aws_api_gateway_api_key.cg_api_key.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.cg_usage_plan.id
}
