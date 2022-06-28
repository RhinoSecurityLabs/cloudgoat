variable "repo_readonly_username" {
  default = "cloner"
}

variable "repository_name" {
  default = "backend-api"
}

// CloudGoat-specific variables
variable "profile" {
}

variable "region" {
  default = "us-east-1"
}
variable "cgid" {

}
variable "cg_whitelist" {
  type = list(any)
}