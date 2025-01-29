# Admin role for EC2
resource "aws_iam_role" "cg_ec2_role" {
  name = "cg_ec2_role_${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "cg_ec2_role" {
  name = "cg_ec2_role_profile_${var.cgid}"
  role = aws_iam_role.cg_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "cg_ec2_role_policy_attach" {
  role       = aws_iam_role.cg_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Dev user (starting user)
resource "aws_iam_user" "cg_dev_user" {
  name = "cg_dev_user_${var.cgid}"
}

resource "aws_iam_user_policy" "cg_dev_ec2_permissions" {
  name = "cg_dev_ec2_permissions_${var.cgid}"
  user = aws_iam_user.cg_dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "ec2:AllocateAddress",
        "ec2:DeleteTags",
        "ec2:AssociateRouteTable",
        "ec2:AttachNetworkInterface",
        "ec2:CreateSecurityGroup",
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_user_policy" "cg_dev_ec2_mgmt_assume" {
  name = "cg_dev_ec2_mgmt_assume_${var.cgid}"
  user = aws_iam_user.cg_dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
      ]
      Effect   = "Allow"
      Resource = "arn:aws:iam::${data.aws_caller_identity.aws-account-id.account_id}:role/cg_ec2_management_role"
    }]
  })
}

resource "aws_iam_user_policy_attachment" "cg_dev_user_policy_attach" {
  user = aws_iam_user.cg_dev_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_access_key" "cg_dev_user_key" {
  user = aws_iam_user.cg_dev_user.name
}

# EC2 management role (pivot role)
resource "aws_iam_role" "cg_ec2_management_role" {
  name = "cg_ec2_management_role_${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.aws-account-id.account_id}:user/cg_dev_user_${var.cgid}"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "cg_ec2_manage_permissions" {
  name = aws_iam_role.cg_ec2_management_role.name
  role = "cg_ec2_management_role_${var.cgid}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "ec2:StartInstances",
		    "ec2:StopInstances",
		    "ec2:ModifyInstanceAttribute",
      ],
      Effect   = "Allow"
      Resource = "*"
      Condition = {
        StringNotEquals = {
          "aws:ResourceTag/Name" = "cg_admin_ec2_${var.cgid}"
        }
      }
    }]
  })
}
