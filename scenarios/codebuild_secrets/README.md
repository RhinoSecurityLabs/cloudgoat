# Scenario: codebuild_secrets

**Size:** Large

**Difficulty:** Hard

**Command:** `$ ./cloudgoat.py create codebuild_secrets`

## Scenario Resources

1 CodeBuild Project

1 Lambda function

1 VPC with:
  * RDS x 1
  * EC2 x 1

2 IAM Users

## Scenario Start(s)

IAM User "Solo"

## Scenario Goal(s)

A pair of secret strings stored in a secure RDS database.

## Summary

Starting as the IAM user Solo, the attacker first enumerates and explores CodeBuild projects, finding unsecured IAM keys for the IAM user Calrissian therein. Then operating as Calrissian, the attacker discovers an RDS database. Unable to access the database's contents directly, the attacker can make clever use of the RDS snapshot functionality to acquire the scenario's goal: a pair of secret strings.

Alternatively, the attacker may explore SSM parameters and find SSH keys to an EC2 instance. Using the metadata service, the attacker can acquire the EC2 instance-profile's keys and push deeper into the target environment, eventually gaining access to the original database and the scenario goal inside (a pair of secret strings) by a more circuitous route.

Note: This scenario may require you to create some AWS resources, and because CloudGoat can only manage resources it creates, you should remove them manually before running `./cloudgoat destroy`.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/3580abff-ea55-4719-a368-8618f8b61370/image.png)

## Walkthrough - Calrissian via RDS Snapshot

1. As the IAM User Solo, the attacker explores the AWS environment and discovers they are able to list CodeBuild projects.
2. Within the CodeBuild project, the attacker discovers IAM keys for the user "Calrissian" stored in environment variables.
3. Assuming the identity of the Calrissian user, the attacker is able to list RDS instances and discover the private database which contains the scenario's goal.
4. While unable to directly access the RDS instance, the attacker is able to create a snapshot from it.
5. The attacker is then able to create a new RDS instance from the snapshot.
6. By resetting the admin password of the newly created RDS instance, the attacker is able to grant themselves access to its contents.
7. After logging into the restored RDS database, the attacker is able to acquire the scenario's goal: the secret strings!

A cheat sheet for this route is available [here](./cheat_sheet_calrissian.md).

## Walkthrough - Solo via EC2 Metadata service

1. As the IAM User Solo, the attacker explores the AWS environment and discovers they are able to list SSM parameters.
2. Among the account's SSM parameters, the attacker finds a pair of SSH keys stored without any encryption.
3. The attacker then lists EC2 instances, looking for somewhere to try the SSH keys they found.
4. After discovering an EC2 instance in the account, the attacker successfully connects to the EC2 instance.

**Branch A**

1. Now working with shell access, the attacker queries the EC2 metadata service and discovers the instance-profile's IAM keys.
2. Using the EC2 instance's profile, the attacker is able enumerate Lambda functions.
3. The attacker discovers admin credentials for the RDS database stored insecurely in Lambda environment variables.
4. Still using the EC2 instance's profile, the attacker lists and accesses the RDS database, and is able to log in using the admin credentials they discovered.
5. With full access to the RDS database, the attacker is able to recover the scenario's goal: A pair of secret strings!

**Branch B**

1. Now working with shell access, the attacker queries the EC2 metadata service and discovers that the database address is stored there, along with admin credentials.
2. Using the RDS credentials and address recovered from the EC2 metadata service, the attacker is able to directly log in to the RDS database.
3. With full access to the RDS database, the attacker is able to recover the scenario's goal: A pair of secret strings!

A cheat sheet for this route is available [here](./cheat_sheet_solo.md).