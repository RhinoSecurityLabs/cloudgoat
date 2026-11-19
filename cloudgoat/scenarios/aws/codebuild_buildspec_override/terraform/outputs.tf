# These outputs are printed to the console and written to start.txt
# when the scenario is created with ./cloudgoat.py create codebuild_buildspec_override

output "cloudgoat_output_bob_access_key_id" {
  description = "Access key ID for the starting IAM user Bob."
  value       = aws_iam_access_key.bob.id
  sensitive   = false
}

output "cloudgoat_output_bob_secret_access_key" {
  description = "Secret access key for the starting IAM user Bob."
  value       = aws_iam_access_key.bob.secret
  sensitive   = true
}

output "cloudgoat_output_aws_account_id" {
  description = "AWS account ID where the scenario was deployed."
  value       = data.aws_caller_identity.current.account_id
}

output "cloudgoat_output_region" {
  description = "AWS region where the scenario was deployed."
  value       = var.region
}

output "cloudgoat_output_codebuild_project_name" {
  description = "Name of the vulnerable CodeBuild project. Discoverable via codebuild:ListProjects."
  value       = aws_codebuild_project.vulnerable.name
}
