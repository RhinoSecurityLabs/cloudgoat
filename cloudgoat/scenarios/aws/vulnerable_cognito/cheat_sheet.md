`aws cognito-idp sign-up --client-id [ClientID] --username [Username] --password [Password] --user-attributes '[{"Name":"given_name","Value":"lorem"},{"Name":"family_name","Value":"ipsum"}]'`

`aws cognito-idp confirm-sign-up --client-id [ClientID] --username [Username] --confirmation-code [ConfirmationCode]`

`aws cognito-idp get-user --access-token [AccessToken]`

`aws cognito-idp update-user-attributes --access-token [AccessToken] --user-attributes '[{"Name":"custom:access","Value":"admin"}]'`

`aws cognito-identity get-id --region [region] --identity-pool-id '[IdentityPool_Id]' --logins "cognito-idp.{region}.amazonaws.com/{UserPoolId}={idToken}"`

`aws cognito-identity get-credentials-for-identity --region [region] --identity-id '[Id-found]' --logins "cognito-idp.{region}.amazonaws.com/{UserPoolId}={idToken}"`
