resource "aws_secretsmanager_secret" "final_flag" {
  name = "${var.cgid}-final_flag"
}

resource "aws_secretsmanager_secret_version" "final_flag_value" {
  secret_id     = aws_secretsmanager_secret.final_flag.id
  secret_string = "cg-secret-846237-284529"
}
