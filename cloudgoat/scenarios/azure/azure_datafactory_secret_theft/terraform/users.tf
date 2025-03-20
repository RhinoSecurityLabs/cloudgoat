data "azuread_domains" "tenant" {}

resource "azuread_user" "cloudgoat_user" {
  user_principal_name = "cloudgoat-user${var.cgid}@${data.azuread_domains.tenant.domains[0].domain_name}"
  display_name        = "CloudGoat User${var.cgid}"
  mail_nickname       = "cloudgoatuser${var.cgid}"
  password           = "${random_password.cloudgoat_password.result}"
}

resource "random_password" "cloudgoat_password" {
  length   = 16
  special  = true
}