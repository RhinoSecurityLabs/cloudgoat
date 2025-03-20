resource "aws_secretsmanager_secret" "easy_secret" {
  name                    = "${var.cgid}_easy_secret"
  description             = "This is the final secret for the 'easy' path of the detection_evasion cloudgoat scenario."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "easy_secret_value" {
  secret_id     = aws_secretsmanager_secret.easy_secret.id
  secret_string = "cg-secret-889877-282341"
}

resource "aws_secretsmanager_secret" "hard_secret" {
  name                    = "${var.cgid}_hard_secret"
  description             = "This is the final secret for the 'hard' path of the detection_evasion cloudgoat scenario."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "hard_secret_value" {
  secret_id     = aws_secretsmanager_secret.hard_secret.id
  secret_string = "cg-secret-012337-194329"
}