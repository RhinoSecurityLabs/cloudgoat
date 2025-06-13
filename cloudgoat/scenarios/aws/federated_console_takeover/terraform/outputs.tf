## Output Configuration for federated_console_takeover scenario

# Initial access credentials
output "initial_access_key_id" {
  value = aws_iam_access_key.initial_user.id
}

output "initial_access_key_secret" {
  value     = aws_iam_access_key.initial_user.secret
  sensitive = true
}


# Scenario instructions
output "cloudgoat_output_message" {
  value = <<EOT
  
========================[ federated_console_takeover ]========================

INITIAL ACCESS:
  AWS Access Key ID: ${aws_iam_access_key.initial_user.id}
  AWS Secret Key: ${aws_iam_access_key.initial_user.secret}
  Region: ${var.region}

SCENARIO OBJECTIVE:
  Pivot from limited AWS CLI access to AWS Management Console 
  with elevated permissions through IMDSv2 exploitation.

========================[ Good luck and happy hacking! ]========================

EOT
  sensitive = true
} 