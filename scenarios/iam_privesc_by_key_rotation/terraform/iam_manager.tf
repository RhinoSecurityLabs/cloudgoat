resource "aws_iam_user" "manager" {
  name          = "manager_${var.cgid}"
  force_destroy = true
}

resource "aws_iam_access_key" "manager" {
  user = aws_iam_user.manager.name
}

resource "aws_iam_user_policy_attachment" "manager_iam_read" {
  user       = aws_iam_user.manager.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_user_policy" "manager_manage_access_keys" {
  name = "SelfManageAccess"
  user = aws_iam_user.manager.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SelfManageAccess"
        Effect = "Allow"
        Action = [
          "iam:DeactivateMFADevice",
          "iam:GetMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "iam:CreateAccessKey"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/developer" = "true"
          }
        }
      },
      {
        Sid    = "CreateMFA"
        Effect = "Allow"
        Action = [
          "iam:DeleteVirtualMFADevice",
          "iam:CreateVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "manager_tag_resources" {
  name = "TagResources"
  user = aws_iam_user.manager.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TagResources"
        Effect = "Allow"
        Action = [
          "iam:UntagUser",
          "iam:UntagRole",
          "iam:TagRole",
          "iam:UntagMFADevice",
          "iam:UntagPolicy",
          "iam:TagMFADevice",
          "iam:TagPolicy",
          "iam:TagUser"
        ]
        Resource = "*"
      }
    ]
  })
}
