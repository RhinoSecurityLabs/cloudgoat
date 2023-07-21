# Scenario: iam_privesc_by_ec2

**Size:** Small

**Difficulty:** Easy

**Command:** `$ ./cloudgoat.py create iam_privesc_by_ec2`

## Scenario Resources

* 1 IAM User
* 1 EC2 Instance
* 2 IAM Roles

## Scenario Start(s)

1. IAM User "cg_dev_user"

## Scenario Goal(s)

Compromise the EC2 "admin_ec2" and gain its admin privileges of the "cg_ec2_role".

## Summary

This is a simple scenario, partially designed to demonstrate the use of [IAMActionHunter](https://github.com/RhinoSecurityLabs/IAMActionHunter) . Starting as the cg_dev_user you need to use your ReadOnly permissions to enumerate the IAM Users and Roles permissions to compromise the "admin_ec2" in the account and gain administrator permissions.

## Walkthrough - IAM User "cg_dev_user"

1. Enumerate IAM permissions for your cg_dev_user and the cg_ec2_management_role
2. Note that you can assume the cg_ec2_management_role role and it has the permissions ec2:stopInstances,ec2:startInstances,ec2:modifyUserAttribute but only resources without a specific tag.
3. cg_dev_user has ec2:deleteTags permission.
4. cg_dev_user deletes the tag from the admin_ec2.
5. cg_dev_user assumes the cg_ec2_management_role and modifies the userdata to run a command to either gain access to it or exfiltrate the credentials from it.

A cheat sheet for this route is available [here](./cheat_sheet_dev_user.md).
