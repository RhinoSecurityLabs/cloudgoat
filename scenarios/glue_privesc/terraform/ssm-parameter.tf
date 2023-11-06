resource "aws_ssm_parameter" "cg-secret-string" {
  name        = "flag"
  description = "this is secret-string"
  type        = "String"
  value       = "Best-of-the-Best-12th-CGV"
  tags = {
    Name     = "cg-secret-string-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}