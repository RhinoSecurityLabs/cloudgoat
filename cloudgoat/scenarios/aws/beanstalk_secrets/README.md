# Scenario: beanstalk_secrets

**Size:** Medium

**Difficulty:** Moderate

**Command:** `./cloudgoat.py create beanstalk_secrets`

## Scenario Resources

- 1 VPC
- 1 Elastic Beanstalk Environment
- 1 IAM Low-Privilege User
- 1 IAM Secondary User
- 1 AWS Secrets Manager Secret

## Scenario Start(s)

1. AWS Access Key and Secret Key for the low-privileged user.

## Scenario Goal(s)

Retrieve the final flag from AWS Secrets Manager by escalating privileges from a low-privileged user to an administrator account.

## Summary

In this scenario, you are provided with low-privileged AWS credentials that grant limited access to Elastic Beanstalk. Your task is to enumerate the Elastic Beanstalk environment and discover misconfigured environment variables containing secondary credentials. Using these secondary credentials, you can enumerate IAM permissions to eventually create an access key for an administrator user. With these admin privileges, you retrieve the final flag stored in AWS Secrets Manager.

## Exploitation Route


![Flowcharts](https://github.com/user-attachments/assets/cf16f767-d8b3-436f-9812-c2d06ea0876b)



## Walkthrough - Elastic Beanstalk Secrets

1. Start by using the provided low-privileged AWS credentials.
2. Verify access with `aws sts get-caller-identity`.
3. Enumerate Elastic Beanstalk applications and environments using Pacu’s `elasticbeanstalk__enum` module.
4. Identify the EB environment with misconfigured environment variables that store secondary credentials.
5. Use the secondary credentials to enumerate IAM resources and permissions.
6. Discover that you can create an access key for an administrator user using the `iam:CreateAccessKey` permission.
7. Generate an admin access key and take over the account.
8. Finally, use the admin privileges to retrieve the final flag from AWS Secrets Manager.

A detailed cheat sheet & walkthrough for this route is available [here](./cheat_sheet.md).
