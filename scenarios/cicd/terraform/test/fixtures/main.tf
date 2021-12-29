variable "region" {}

resource "random_string" "cgid" {
  length  = 8
  special = false
  min_lower = 4
  min_numeric = 4
}


module "scenario" {
  source                 = "../../"
  repo_readonly_username = "cloner"
  repository_name        = "backend-api"
  region                 = var.region

  # Cloudgoat variables
  profile      = "unused"
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
