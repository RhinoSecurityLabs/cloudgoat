# Scenario: RDS_snapshot

**Size:** Small

**Difficulty:** Easy

**Command:** `$ ./cloudgoat.py create RDS_snapshot`

## Scenario Resources

* 1 VPC with:
  * EC2 x 1
  * S3 x 1
  * RDS x 1
* 1 IAM Users

## Scenario Start(s)

1. IAM User "David"

## Scenario Goal(s)

Get the flags that are included in the RDS snapshot.

## Summary


Starting with access to EC2, the user can leverage the privileges of the EC2 instance to steal credentials from S3. 

With the stolen credentials, the attacker can gain RDS Snapshot restore privileges, which will allow them to access the DB and retrieve flags.
## Exploitation Route(s)

![Scenario Route(s)](https://github.com/RhinoSecurityLabs/cloudgoat/assets/55736240/bff418b2-f656-4851-9f8d-00288c66e3fa)




## Route Walkthrough - IAM User “David”

1. the attacker gains access to the hijacked EC2 instance.
2. The attacker accesses S3 on the compromised EC2 instance and retrieves credentials.
3. The attacker uses the stolen credentials to locate and access the AWS Relational Database Service (RDS).
4. The attacker verifies that an RDS snapshot exists.
5. The attacker restores the RDS snapshot and hijacks the DB containing customer data (Flag).

A cheat sheet for this route is available [here](./cheat_sheet.md).