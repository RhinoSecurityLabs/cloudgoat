`aws cognito-idp sign-up --client-id '[ClientId]' --username '[Email]' --password '[Password]' --user-attributes '[{"Name":"given_name","Value":"lorem"},{"Name":"family_name","Value":"ipsum"}]'`


`aws cognito-idp confirm-sign-up --client-id '[ClientId]' --username '[Email]' --confirmation-code '[Code]'`


`aws cognito-idp get-user --access-token '[AccessToken]'`


`aws cognito-idp update-user-attributes --access-token '[AccessToken]' --user-attributes '[{"Name":"custom:access","Value":"admin"}]'`

