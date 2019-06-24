resource "null_resource" "cg-create-iam-user-policy-version-2" {
  provisioner "local-exec" {
      command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.cg-raynor-policy.arn} --policy-document file://../assets/policies/v2.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "cg-create-iam-user-policy-version-3" {
  provisioner "local-exec" {
      command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.cg-raynor-policy.arn} --policy-document file://../assets/policies/v3.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "cg-create-iam-user-policy-version-4" {
  provisioner "local-exec" {
      command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.cg-raynor-policy.arn} --policy-document file://../assets/policies/v4.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "cg-create-iam-user-policy-version-5" {
  provisioner "local-exec" {
      command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.cg-raynor-policy.arn} --policy-document file://../assets/policies/v5.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}