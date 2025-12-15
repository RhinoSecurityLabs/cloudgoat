Scenario: data_secrets
======================

**Size:** Small

**Difficulty:** Easy

**Command:** `./cloudgoat.py create data_secrets`

Scenario Resources
------------------

-   1 IAM User

-   1 EC2 Instance

-   1 IAM Role

-   1 Lambda Function

-   1 Secrets Manager Secret

Scenario Start(s)
-----------------

1.  AWS Access Key and Secret Key

Scenario Goal(s)
----------------

Retrieve the final flag stored in the AWS Secrets Manager.

Summary
-------

In this scenario, you start with an IAM user with limited permissions. Your task is to identify a misconfigured EC2 instance leaking credentials in its User Data, allowing you to gain SSH access. From there, you must pivot by exploiting the Instance Metadata Service (IMDS) to steal a role, enumerate Lambda functions to find hidden environment variables, and finally compromise a user with access to the scenario's objective: a secret stored in AWS Secrets Manager.

Exploitation Route
------------------

Walkthrough - Data Secrets
--------------------------

1.  Start by configuring your AWS CLI with the provided starting credentials.

2.  Enumerate your permissions to discover the ability to read EC2 attributes.

3.  Inspect the EC2 User Data to find hardcoded system user credentials.

4.  SSH into the exposed EC2 instance using the credentials found in the User Data.

5.  Query the EC2 Instance Metadata Service (IMDS) to steal the temporary credentials for the attached IAM Instance Profile.

6.  Use the stolen session credentials to enumerate Lambda functions and view their configurations.

7.  Discover a set of hardcoded AWS Access Keys hidden inside a Lambda function's Environment Variables.

8.  Configure a final profile with these keys and use them to retrieve the flag from AWS Secrets Manager.

A detailed cheat sheet & walkthrough for this route is available [here](./cheat_sheet.md). 