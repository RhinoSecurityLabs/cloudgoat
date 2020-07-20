# Scenario: ecs_efs_attack

**Size:** Large

**Difficulty:** Hard

**Command:** `$ ./cloudgoat.py create ecs_efs_attack`

## Scenario Resources

- 1 VPC with:
	- EC2 x 2
	- 1 ECS Cluster
	- 1 ECS Service 
	- 1 EFS

## Scenario Start(s)

1. Access to "Ruse_Box" EC2

## Scenario Goal(s)

Mount the "cg-efs-[CG_ID]" efs and obtain the flag.

## Summary

Starting with access the first EC2 the user uses the instace profile to view and backdoor the running ecs service. The attacker then modifies the existing task definition to retireve credentials from the metadata api. These credentials allow the attacker to start a session on any EC2 with the proper tags set. The attacker uses their permissions to change the tags on the Admin EC2 and starts a session. Once in the Admin EC2 the attacker will port scan for EFS and attempt to mount the EFS. Once mounted the attacker can retuirnve the flag from the file system.

## Exploitation Route(s)

![Scenario Route(s)](https://app.lucidchart.com/publicSegments/view/cf6f134d-7e28-4561-9cbb-b50e6666468d/image.png)

## Route Walkthrough - IAM User "Solus"

1. Access the "Ruse_Box" ec2 using the provied access key.
2. From the ec2 enumate permission. Then list avaible ec2 and note how the tags are configured.
3. From the current ec2 enumate existing ecs cluster and backdoor the existing task defniniton.
4. Update the existing service in the ecs cluster to execute the payload.
5. From the container credentilas use the SSM:StartSession privlage to access the admin_box.
6. Port scan the subnet to find avaible efs and mount.

A cheat sheet for this route is available [here](./cheat_sheet_solus.md).