resource "null_resource" "policy_version" {
  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.versioned_policy.arn} --policy-document file://policies/v2.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }

  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.versioned_policy.arn} --policy-document file://policies/v3.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }

  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.versioned_policy.arn} --policy-document file://policies/v4.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }

  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.versioned_policy.arn} --policy-document file://policies/v5.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
