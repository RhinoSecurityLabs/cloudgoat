# Create SES for sending emails.
resource "aws_ses_email_identity" "email" {
  email = var.user_email
}