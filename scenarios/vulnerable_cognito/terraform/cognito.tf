resource "aws_cognito_user_pool" "ctf_pool" {
  name = "CognitoCTF-${var.cgid}"
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  lambda_config {
    post_confirmation = aws_lambda_function.test_lambda.arn
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  auto_verified_attributes = ["email"]

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  schema {
    name                = "access"
    mutable             = true
    attribute_data_type = "String"
  }

  schema {
    name                = "email"
    required            = true
    attribute_data_type = "String"
  }

  schema {
    name                = "given_name"
    required            = true
    attribute_data_type = "String"
  }

  schema {
    name                = "family_name"
    required            = true
    attribute_data_type = "String"
  }

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  username_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  mfa_configuration = "OFF"
}

resource "aws_cognito_user_pool_client" "cognito_client" {
  explicit_auth_flows    = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
  auth_session_validity  = 3
  refresh_token_validity = 30
  access_token_validity  = 60
  id_token_validity      = 60
  token_validity_units {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "phone", "email"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["https://example.com/"]
  allowed_oauth_flows_user_pool_client = true
  name                                 = "CognitoClient-${var.cgid}"
  user_pool_id                         = aws_cognito_user_pool.ctf_pool.id
  generate_secret                      = false
  read_attributes                      = ["address", "birthdate", "custom:access", "email", "email_verified", "family_name", "gender", "given_name", "locale", "middle_name", "name", "nickname", "phone_number", "phone_number_verified", "picture", "preferred_username", "profile", "updated_at", "website", "zoneinfo"]
  write_attributes                     = ["address", "birthdate", "custom:access", "email", "family_name", "gender", "given_name", "locale", "middle_name", "name", "nickname", "phone_number", "picture", "preferred_username", "profile", "updated_at", "website", "zoneinfo"]
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "cognito_identitypool-${var.cgid}"
  allow_unauthenticated_identities = false
  allow_classic_flow               = true

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.cognito_client.id
    provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.ctf_pool.id}"
    server_side_token_check = false
  }

}

resource "aws_iam_role" "authenticated" {
  name = "cognito_authenticated-${var.cgid}"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = "cognito-identity.amazonaws.com"
          },
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
            }
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "authenticated"
            }
          }
        }
      ]
    }
  )

  inline_policy {
    name = "authenticated_policy-${var.cgid}"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow",
            Action = [
              "s3:*",
              "cognitoidp:*",
              "cognito-identity:*",
              "lambda:*"
            ]
            Resource = [
              "*"
            ]
          }
        ]
      }
    )
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.authenticated.arn
  }
}
