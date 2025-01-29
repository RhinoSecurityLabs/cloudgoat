locals {
  # Ensure the suffix doesn't contain invalid characters
  # Resources names can consist only of lowercase letters, numbers, dots (.), and hyphens (-).
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
  cgid_suffix = replace(var.cgid, "/[^a-z0-9-.]/", "-")
}
