resource "aws_secretsmanager_secret" "final_flag" {
  name = "cg-final-flag-${var.cgid}"
  description = "The final flag for the CloudGoat scenario"
  
  tags = {
    Name = "cg-final-flag-${var.cgid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_secretsmanager_secret_version" "final_flag_value" {
  secret_id     = aws_secretsmanager_secret.final_flag.id
  secret_string = jsonencode({
    flag = "cloudgoat{d4t4_s3cr3ts_4r3_fun}"
  })
}