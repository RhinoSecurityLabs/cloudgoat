terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      ManagedBy = "cloudgoat"
      Scenario  = "codebuild_buildspec_override"
      CGID      = var.cgid
    }
  }
}

# -----------------------------------------------------------------------
# Data
# -----------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------
# Secrets Manager — the flag the attacker is after
# -----------------------------------------------------------------------

resource "aws_secretsmanager_secret" "flag" {
  name                    = "cg-flag-${var.cgid}"
  description             = "CloudGoat codebuild_buildspec_override scenario flag."
  recovery_window_in_days = 0 # Instant deletion on destroy
}

resource "aws_secretsmanager_secret_version" "flag" {
  secret_id = aws_secretsmanager_secret.flag.id

  secret_string = jsonencode({
    flag = "Congratulations, you successfully injected the commands and escalated the privileges"
  })
}

# -----------------------------------------------------------------------
# IAM — CodeBuild service role (privileged)
# -----------------------------------------------------------------------

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    sid     = "CodeBuildAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_service" {
  name               = "cg-codebuild-service-role-${var.cgid}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  description        = "Service role for the vulnerable CodeBuild project."
}

data "aws_iam_policy_document" "codebuild_service_permissions" {
  # Lets the injected buildspec enumerate secret names at runtime;
  # ListSecrets takes no secret identifier as input and only supports the
  # "*" resource, it cannot be scoped to a single secret ARN
  statement {
    sid    = "SecretList"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }

  # Read access scoped to this project's own secret; the exploited
  # misconfiguration is the buildspec override, not the permission's scope
  statement {
    sid    = "SecretRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.flag.arn]
  }

  # Minimal CodeBuild logging permissions so builds can run
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_service" {
  name   = "cg-codebuild-service-policy-${var.cgid}"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_service_permissions.json
}

# -----------------------------------------------------------------------
# IAM — Bob, the low-privileged starting user
# -----------------------------------------------------------------------

resource "aws_iam_user" "bob" {
  name = "cg-bob-${var.cgid}"
}

resource "aws_iam_access_key" "bob" {
  user = aws_iam_user.bob.name
}

data "aws_iam_policy_document" "bob_permissions" {
  # Only enough to discover, inspect, and start builds — no Secrets Manager access
  statement {
    sid    = "CodeBuildLimitedAccess"
    effect = "Allow"
    actions = [
      "codebuild:ListProjects",
      "codebuild:BatchGetProjects",
      "codebuild:StartBuild",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "bob" {
  name   = "cg-bob-policy-${var.cgid}"
  user   = aws_iam_user.bob.name
  policy = data.aws_iam_policy_document.bob_permissions.json
}

# -----------------------------------------------------------------------
# CodeBuild — vulnerable project
# -----------------------------------------------------------------------

resource "aws_codebuild_project" "vulnerable" {
  name          = "cg-vulnerable-project-${var.cgid}"
  description   = "A CodeBuild project with a privileged service role. The buildspec can be overridden at start time."
  service_role  = aws_iam_role.codebuild_service.arn
  build_timeout = 10 # minutes

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  # Default buildspec — benign; the attacker overrides this at build start time
  source {
    type      = "NO_SOURCE"
    buildspec = <<-BUILDSPEC
      version: 0.2
      phases:
        build:
          commands:
            - echo "Default build — nothing to do here."
    BUILDSPEC
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  depends_on = [
    aws_iam_role_policy.codebuild_service
  ]
}
