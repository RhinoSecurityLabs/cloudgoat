resource "aws_secretsmanager_secret" "final_flag" {
  name = "${var.cgid}_final_flag"
}

resource "aws_secretsmanager_secret_version" "final_flag" {
  secret_id     = aws_secretsmanager_secret.final_flag.id
  secret_string = var.final_flag
}