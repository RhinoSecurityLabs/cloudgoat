#############################
# Administrator Privilege User
#############################

resource "aws_iam_user" "admin_user" {
  name = "${var.cgid}_admin_user"
  force_destroy = true
}

resource "aws_iam_policy" "admin_user_policy" {
  name = "${var.cgid}_admin_user_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "*",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "admin_user_policy_attach" {
  user       = aws_iam_user.admin_user.name
  policy_arn = aws_iam_policy.admin_user_policy.arn
}

#############################
# Low-Privileged User (Initial Credentials)
#############################

resource "aws_iam_user" "low_priv_user" {
  name = "${var.cgid}_low_priv_user"
}

resource "aws_iam_access_key" "low_priv_key" {
  user = aws_iam_user.low_priv_user.name
}

resource "aws_iam_policy" "low_priv_policy" {
  name = "${var.cgid}_low_priv_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: [
          "elasticbeanstalk:DescribeApplications",
          "elasticbeanstalk:DescribeApplicationVersions",
          "elasticbeanstalk:DescribeConfigurationSettings",
          "elasticbeanstalk:DescribeEnvironmentHealth",
          "elasticbeanstalk:DescribeEnvironmentResources",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticbeanstalk:DescribeEvents",
          "elasticbeanstalk:ListAvailableSolutionStacks",
          "elasticbeanstalk:ListTagsForResource",
          "ec2:DescribeSubnets"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "s3:*"
        ],
        Resource: [
          "arn:aws:s3:::elasticbeanstalk*", 
          "arn:aws:s3:::elasticbeanstalk*/*"
        ] 
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "low_priv_policy_attach" {
  user       = aws_iam_user.low_priv_user.name
  policy_arn = aws_iam_policy.low_priv_policy.arn
}

#############################
# Secondary Credentials (Discovered in EB Config)
#############################

resource "aws_iam_user" "secondary_user" {
  name = "${var.cgid}_secondary_user"
}

resource "aws_iam_access_key" "secondary_key" {
  user = aws_iam_user.secondary_user.name
}

resource "aws_iam_policy" "secondary_policy" {
  name = "${var.cgid}_secondary_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "iam:CreateAccessKey"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:ListRoles",
          "iam:GetRole",
          "iam:ListPolicies",
          "iam:GetPolicy",
          "iam:ListPolicyVersions",
          "iam:GetPolicyVersion",
          "iam:ListUsers",
          "iam:GetUser",
          "iam:ListGroups",
          "iam:GetGroup",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetRolePolicy"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "secondary_policy_attach" {
  user       = aws_iam_user.secondary_user.name
  policy_arn = aws_iam_policy.secondary_policy.arn
}

#############################
# Elastic Beanstalk IAM Roles and Instance Profile
#############################

# Role for EB EC2 Instances
resource "aws_iam_role" "eb_instance_role" {
  name = "${var.cgid}_eb_instance_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "${var.cgid}_eb_instance_profile"
  role = aws_iam_role.eb_instance_role.name
}

# Role for the Elastic Beanstalk service
resource "aws_iam_role" "eb_service_role" {
  name = "${var.cgid}_eb_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })
}
