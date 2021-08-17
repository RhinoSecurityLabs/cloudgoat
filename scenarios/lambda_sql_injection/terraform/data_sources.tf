#AWS Account Id
data "aws_caller_identity" "aws-account-id" {

}
#Administrator Policy
data "aws_iam_policy" "administrator-full-access" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}