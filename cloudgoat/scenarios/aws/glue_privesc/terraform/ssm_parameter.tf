resource "aws_ssm_parameter" "flag" {
  name        = "flag"
  description = "this is secret secret-string"
  type        = "String"
  value       = "flag{Best-of-the-Best-12th-CGV}"
}
