#AWS Account Id
data "aws_caller_identity" "aws-account-id" {
  
}
#Policy Versions
data "local_file" "v1" {
  filename = "../assets/policies/v1.json"
}
data "local_file" "v2" {
  filename = "../assets/policies/v2.json"
}
data "local_file" "v3" {
  filename = "../assets/policies/v3.json"
}
data "local_file" "v4" {
  filename = "../assets/policies/v4.json"
}
data "local_file" "v5" {
  filename = "../assets/policies/v5.json"
}