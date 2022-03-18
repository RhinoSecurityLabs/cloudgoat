resource "aws_iam_user" "initial" {
  name = local.initial_username
}
resource "aws_iam_user_policy" "initial" {
  name = "initial-policy"
  user = aws_iam_user.initial.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
          "ec2:CreateTags",
          "ec2:DeleteTags"
      ],
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/Environment": [
            "dev"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
          "ssm:*"
      ],
      "Condition": {
        "StringLike": {
          "ssm:ResourceTag/Environment": [
            "sandbox"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*::document/*",
      "Action": [
          "ssm:*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
          "iam:List*",
          "iam:Describe*",
          "iam:Get*",
          "ec2:Describe*",
          "ec2:List*",
          "ssm:Describe*",
          "ssm:Get*",
          "codecommit:ListRepositories"
      ]
    },
    {
      "Effect": "Deny",
      "Resource": "*", 
      "Action": "ec2:DescribeInstanceAttribute"
    },
    {
      "Effect": "Allow",
      "Sid": "AllowConsoleAccess",
      "Resource": "arn:aws:sts::${local.account_id}:federated-user/${aws_iam_user.initial.name}",
      "Action": "sts:GetFederationToken"
    }
  ]
}
POLICY
}

resource "aws_iam_access_key" "initial" {
  user = aws_iam_user.initial.name
}