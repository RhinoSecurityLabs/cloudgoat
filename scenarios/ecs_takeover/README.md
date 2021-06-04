# Scenario: ecs_efs_attack

**Size:** Medium

**Difficulty:** Medium

**Command:** `$ ./cloudgoat.py create ecs_takeover`

## Scenario Resources

- 1 VPC with:
    - EC2 x 2
    - 1 ECS Cluster
    - 2 ECS Service
    - 1 ECS Task 
    - 1 ALB
    - 1 NAT Gateway

## Scenario Start(s)

1. Access the external website via the ALB DNS name.

## Scenario Goal(s)

Gain access to the "vault" container and retrieve the flag.

## Summary

Starting with access to the external website the attacker needs to find a remote code execution vulnerability. By using RCE the attacker can get a reverse shell on the website's container instance. Enumerating the container configuration the attacker finds the host's Docker socket is mounted in the container giving access to docker on the host instance. Abusing this misconfiguration the attacker can deploy a new container to gain access to the host instance. Now the attacker can enumerate other running containers on the instance and compromise the container role of a privileged container. Using these new IAM privileges the attacker can enumerate the worker nodes of the ECS cluster and running tasks. Another task "vault" is discovered to be running on a separate worker node. Using the host container privileges the attacker modifies the state of the cluster and forces ECS to reschedule the container to the compromised host allowing the attacker to access the flag on the "vault" container instance. 

## Exploitation Route(s)

![Scenario Route(s)](assets/diagram.png)

## Route Walkthrough 

1. Access the website using the provided URL.
2. Exploit RCE vulnerability to get a shell on the website's container.
3. leverage the docker socket mounted in the container to escape to the host instance.
4. Enuemate and compromise the container credentials of "privd" container running on the host instance.
5. Use the container role to find the other worker node and "vault" task.
6. Using IAM privileged of the worker node, deregister or drain the other worker instance.
7. Wait for the "vault" container to be rescheduled and deployed to the attacker's worker instance.

**A cheat sheet for this route is available [here](./cheat_sheet.md).**
