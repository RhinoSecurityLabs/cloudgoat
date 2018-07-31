resource "aws_iam_role" "codebuild_project" {
  name = "codebuild_project"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_iam_policy" {
  name = "policy_for_codebuild_role"
  role = "${aws_iam_role.codebuild_project.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codebuild:*",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetRepository",
        "codecommit:ListBranches",
        "codecommit:ListRepositories",
        "cloudwatch:GetMetricStatistics",
        "ec2:DescribeVpcs",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:GetLogEvents"
      ],
      "Effect": "Allow",
        "Resource": "arn:aws:logs:*:*:log-group:/aws/codebuild/*:log-stream:*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:PutParameter"
        ],
        "Resource": "arn:aws:ssm:*:*:parameter/CodeBuild/*"
      }
    ]
}
EOF
}

resource "aws_codebuild_project" "cloudgoat_project" {
  name         = "cloudgoat_project"
  service_role = "${aws_iam_role.codebuild_project.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:6.3.1"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "kinda_secret"
      "value" = "ASHHJ#HIJBKSDBSKJN!55JNDKN!KJND!KJDN2KN"
      "type"  = "PLAINTEXT"
    }

    environment_variable {
      "name"  = "super_secret"
      "value" = "dhSJKl2*@6d6&@d82hk2bn1n1n"
      "type"  = "PLAINTEXT"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/RhinoSecurityLabs/cloudgoat.git"
  }
}
