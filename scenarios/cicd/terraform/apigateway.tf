resource "aws_apigatewayv2_api" "apigw" {
  name          = local.api_gateway_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.apigw.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = module.lambda_function_container_image.lambda_function_invoke_arn
  payload_format_version = "1.0"
  passthrough_behavior   = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "main_route" {
  api_id             = aws_apigatewayv2_api.apigw.id
  route_key          = "POST ${local.api_gateway_route}"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  request_parameter {
    request_parameter_key = "route.request.header.Authorization"
    required              = false
  }
}

resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_route.main_route.api_id
  description = "Main deployment"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id        = aws_apigatewayv2_api.apigw.id
  deployment_id = aws_apigatewayv2_deployment.example.id
  name          = "prod"
}