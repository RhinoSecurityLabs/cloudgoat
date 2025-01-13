#AWS Account Id
data "aws_caller_identity" "aws-account-id" {}

locals {
  default_tags = {
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
