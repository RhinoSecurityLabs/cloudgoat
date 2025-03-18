locals {
  # Ensure resource suffixes the bucket suffix doesn't contain anything else than
  # lowercase letters, numbers, and hyphens
  # Used for RDS, load balancer and S3
  cgid_suffix = replace(var.cgid, "/[^a-z0-9-]/", "-")

  default_tags = {
    Scenario = var.scenario-name
    Stack    = var.stack-name
  }
}
