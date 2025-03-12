# This Terraform file creates the following resources for the AWS Secret's Manager:
# - A variable containing a regular expression for the secrets suffix.
# - An AWS Secret Manager Secret
# - An AWS Secret Manager Secret Version
# - An AWS Secret Manager Secret Policy

resource "aws_secretsmanager_secret" "this" {
  name        = "cg-secret-${local.cgid_suffix}"
  description = "A secret for CloudGoat scenario"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    super_key                          = "JohnsJuicyJam"
    mega_secret                        = "BensBubblyBacon"
    ultra_mega_secret                  = "BenjaminsBlazingBungee"
    RyansRambunctiousRhinocerosRampage = "Congrats, you have successfully completed Secrets in the Cloud!"
  })
}

resource "aws_secretsmanager_secret_policy" "this" {
  secret_arn = aws_secretsmanager_secret.this.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "secretsmanager:GetSecretValue"
        Effect    = "Allow"
        Resource  = aws_secretsmanager_secret.this.arn
        Principal = "*"
      }
    ]
  })
}
