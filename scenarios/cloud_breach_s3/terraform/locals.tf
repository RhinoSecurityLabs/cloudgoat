locals {
  s3_bucket_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")

  s3_objects = [
    "cardholder_data_primary.csv",
    "cardholder_data_secondary.csv",
    "cardholders_corporate.csv",
    "goat.png"
  ]

  default_tags = {
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
