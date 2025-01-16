# Secret that is the flag for the scenario
resource "aws_secretsmanager_secret" "primary_secret" {
  name                    = "cg_secret_${var.cgid}"
  description             = "The primary secret for the ${var.scenario-name} scenario"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "primary_secret_string" {
  secret_id     = aws_secretsmanager_secret.primary_secret.id
  secret_string = "flag{14m_PERM15510N5_4Re_5C4R_${sha256(formatdate("DD-MM-YYYY", timestamp()))}}"
}
