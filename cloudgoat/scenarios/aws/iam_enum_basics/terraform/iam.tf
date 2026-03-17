# User: Bob (The starting point)
resource "aws_iam_user" "bob" {
  name = "cg-bob-${var.cgid}"
  
  # A little breadcrumb tag just for fun
  tags = {
    "Message" = "Enumerate me"
  }
}

resource "aws_iam_access_key" "bob_keys" {
  user = aws_iam_user.bob.name
}

# ------------------------------------------------------------------
# BASE PERMISSIONS: Allow Bob to actually enumerate IAM
# ------------------------------------------------------------------
resource "aws_iam_user_policy_attachment" "bob_base_permissions" {
  user       = aws_iam_user.bob.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

# ------------------------------------------------------------------
# FLAG 1: Managed Policy (Hidden in the Description)
# FLAG 5: Managed Policy JSON (Hidden in the Resource ARN)
# ------------------------------------------------------------------
resource "aws_iam_policy" "flag1_managed_policy" {
  name        = "cg-flag1-managed-policy-${var.cgid}"
  # FLAG 1 is right here in the description
  description = "HSM{m4n4g3d_p0l1cy_m4st3r}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        # FLAG 5 is hidden as the target resource
        Resource = "arn:aws:s3:::HSM{s3cr3t_js0n_str1ng}"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "bob_managed_attach" {
  user       = aws_iam_user.bob.name
  policy_arn = aws_iam_policy.flag1_managed_policy.arn
}

# ------------------------------------------------------------------
# FLAG 2: Inline Policy (Hidden in the Statement ID 'Sid')
# ------------------------------------------------------------------
resource "aws_iam_user_policy" "flag2_inline_policy" {
  name = "cg-flag2-inline-policy-${var.cgid}"
  user = aws_iam_user.bob.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # FLAG 2 is hidden as the Statement ID
        Sid      = "HSM1nl1n3p0l1cyd1sc0v3r3d" # Sids must be alphanumeric, no braces allowed natively, but we can do our best or format it as HSM1nl1n3
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------
# FLAG 3: Specific Group (Hidden in the IAM Path)
# ------------------------------------------------------------------
resource "aws_iam_group" "flag3_group" {
  name = "cg-flag3-group-${var.cgid}"
  # FLAG 3 is hidden in the organizational path of the group
  path = "/HSM_gr0up_m3mb3rsh1p_f0und/"
}

resource "aws_iam_group_membership" "bob_group_membership" {
  name  = "cg-bob-group-membership-${var.cgid}"
  users = [aws_iam_user.bob.name]
  group = aws_iam_group.flag3_group.name
}

# ------------------------------------------------------------------
# FLAG 4: Assumable Role (Hidden in the Role Tags)
# ------------------------------------------------------------------
resource "aws_iam_role" "flag4_role" {
  name = "cg-flag4-role-${var.cgid}"
  
  # FLAG 4 is hidden in the AWS tags
  tags = {
    "Flag" = "HSM-r0l3_trus1_f0und"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_user.bob.arn
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flag4_role_policy" {
  name = "cg-flag4-role-policy-${var.cgid}"
  role = aws_iam_role.flag4_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "iam:ListUsers"
        Resource = "*"
      }
    ]
  })
}