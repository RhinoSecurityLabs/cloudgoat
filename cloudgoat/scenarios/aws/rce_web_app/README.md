# Scenario: rce_web_app

**Size:** Medium

**Difficulty:** Hard

**Command:** `$ ./cloudgoat.py create rce_web_app`

## Scenario Resources

* 1 VPC with:
  * ELB x 1
  * EC2 x 1
  * S3 x 3
  * RDS x 1
* 2 IAM Users

## Scenario Start(s)

1. IAM User "Lara"
2. IAM User "McDuck"

## Scenario Goal(s)

Find a secret stored in the RDS database.

## Summary

Starting as the IAM user Lara, the attacker explores a Load Balancer and S3 bucket for clues to vulnerabilities, leading to an RCE exploit on a vulnerable web app which exposes confidential files and culminates in access to the scenario’s goal: a highly-secured RDS database instance.

Alternatively, the attacker may start as the IAM user McDuck and enumerate S3 buckets, eventually leading to SSH keys which grant direct access to the EC2 server and the database beyond.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/1b75f181-4d6e-4ad7-b3fb-56dd54efab66/image.png)

## Route Walkthrough - IAM User “Lara”

1. As the IAM user Lara, the attacker explores the AWS environment and discovers a web application hosted behind a secured Load Balancer.
2. The attacker then lists S3 buckets, discovering one which contains the logs for the Load Balancer.
3. While reviewing the contents of the Load Balancer logs, the attacker sees that the web app has a secret admin page.
4. Upon visiting the secret admin URL, the attacker discovers that the web app is vulnerable to a remote code execution (RCE) attack via a secret parameter embedded in a form.
5. The attacker leverages this vulnerability to gain shell access on the EC2 instance hosting the web app.

**Branch A**

1. Now working through the EC2 instance (and therefore operating with its role's more expansive permissions), the attacker is able to access a private S3 bucket.
2. Inside the private S3 bucket, the attacker finds a text file left behind by an irresponsible developer which contains the login credentials for an RDS database.
3. The attacker then uses the EC2 instance to list and discover the RDS database referenced in the credentials file.
4. Finally, the attacker is able to access the RDS database using the credentials they found and acquires the scenario's goal: the secret text stored in the RDS database!

**Branch B**

1. Struck by sudden inspiration, the attacker queries the EC2 metadata service and discovers the RDS database credentials and address.
2. The attacker is then able to access the RDS database using the credentials they found and acquires the scenario's goal: the secret text stored in the RDS database!

A cheat sheet for this route is available [here](./cheat_sheet_lara.md).

## Route Walkthrough - IAM User “McDuck”

1. The attacker explores the AWS environment and discovers they are able to list S3 buckets using their starting keys.
2. The attacker discovers several S3 buckets, but they are only able to access one of them. Inside that one S3 bucket they find a pair of SSH keys.
3. The attacker lists EC2 instances and finds the EC2 instance behind the Load Balancer.
4. The attacker discovers that the SSH keys found in the S3 bucket enable the attacker to log into the EC2 instance.
5. Now working through the EC2 instance (and therefore operating with its role instead of McDuck's), the attacker is able to discover and access a private S3 bucket.
7. Inside the private S3 bucket, the attacker finds a text file left behind by an irresponsible developer which contains the login credentials for an RDS database.
7. The attacker is able to list and discover the RDS database referenced in the credentials file.
8. The attacker is finally able to access the RDB database using the credentials they found in step 6 and acquire the scenario's goal: the secret text stored in the RDS database.

A cheat sheet for this route is available [here](./cheat_sheet_mcduck.md).