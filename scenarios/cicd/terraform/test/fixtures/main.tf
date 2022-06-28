variable "region" {}

resource "random_string" "cgid" {
  length  = 8
  special = false
  min_lower = 4
  min_numeric = 4
}

locals {
  profile = yamldecode(file("${path.module}/../../../../../config.yml"))[0]["default-profile"]
}


module "scenario" {
  source                 = "../../"
  repo_readonly_username = "cloner"
  repository_name        = "backend-api"
  region                 = var.region

  # Cloudgoat variables

  // Use the default profile for tests, this behavior is mentioned in the test README.md.
  profile      = local.profile

  cgid         = random_string.cgid.result
  cg_whitelist = []
}

output "access_key_id" {
  value     = module.scenario.cloudgoat_output_access_key_id
  sensitive = true
}
output "secret_access_key" {
  value     = module.scenario.cloudgoat_output_secret_access_key
  sensitive = true
}
output "api_url" {
  value = module.scenario.cloudgoat_output_api_url
}
