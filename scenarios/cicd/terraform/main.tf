data "aws_caller_identity" "current" {}

locals {
  repository_name         = var.repository_name
  api_gateway_name        = "main-apigw"
  api_gateway_route       = "/hello"
  lambda_function_name    = "backend-api"
  codepipeline_name       = "deployment-pipeline"
  ecr_repository_name     = "backend-api"
  vpc_name                = "main-vpc"
  initial_username        = "ec2-sandbox-manager"
  repo_readonly_username  = var.repo_readonly_username
  repo_readwrite_username = "developer"
  account_id              = data.aws_caller_identity.current.account_id
}
