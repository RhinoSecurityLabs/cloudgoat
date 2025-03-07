output "initial_low_priv_credentials" {
  description = "Initial low-privileged credentials provided to the scenario"
  value = <<EOF
Access Key: ${aws_iam_access_key.low_priv_key.id}
Secret Key: ${aws_iam_access_key.low_priv_key.secret}
EOF
  sensitive = true
}