# Scenario: ecs_efs_attack

**Size:** Large

**Difficulty:** Hard

**Command:** `$ ./cloudgoat.py create ec2_ssrf`

## Scenario Resources

- 1 VPC with:
	- EC2 x 2
	- 1 ECS Cluster
	- 1 ECS Service 
	- 1 EFS

## Scenario Start(s)

1. Access to "Ruse_Box" EC2

## Scenario Goal(s)

Mount the "cg-efs=[CG_ID]" efs and obtain the flag.

## Summary

Starting with access the first EC2 the user uses the instace profile to view and backdoor the running ecs service. The attacker then modifies the existing task defneitoins to retireve credntils from the metadata api. The new crednetials allow the to start a session on any EC2 with the proper tags set. When the tags are properly set the attacker can access the admin ec2. Once in the admin ec2 the attacker will port scan for an efs and attempt to mount the efs. Once mounted the attacker can retuirnve the flag from the file system.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/3117f737-3290-48c6-b0bf-e122a305858d/image.png)

## Route Walkthrough - IAM User "Solus"

1. Access the "Ruse_Box" ec2 using the provied access key.
2. From the ec2 enumate permission. Then list avaible ec2 and note how the tags are configured.
3. From the current ec2 enumate existing ecs cluster and backdoor the existing task defniniton.
4. Update the existing service in the ecs cluster to execute the payload.
5. From the container credentilas use the SSM:StartSession privlage to access the admin_box.
6. Port scan the subnet to find avaible efs and mount.

A cheat sheet for this route is available [here](./cheat_sheet_solus.md).