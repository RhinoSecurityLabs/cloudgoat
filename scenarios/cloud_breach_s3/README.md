# Scenario: cloud_breach_s3

**Size:** Small

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create cloud_breach_s3`

## Scenario Resources

* 1 VPC with:
  * EC2 x 1
  * S3 x 1

## Scenario Start(s)

1. The IP Address of an EC2 server that is running a misconfigured reverse proxy

## Scenario Goal(s)

Download the confidential files from the S3 bucket.

## Summary

Starting as an anonymous outsider with no access or privileges, exploit a misconfigured reverse-proxy server to query the EC2 metadata service and acquire instance profile keys. Then, use those keys to discover, access, and exfiltrate sensitive data from an S3 bucket.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/3ffe907e-6281-47e9-b7bf-e07fdcb48103/image.png)

## Route Walkthrough - Anonymous Attacker

1. The attacker finds the IP of an EC2 instance by shady means, and after some reconnaissance realizes that it is acting as a reverse-proxy server. This is common, especially for organizations in the process of moving from on-premise to the cloud.
2. After some research, the attacker uses `CURL` to send a request to the web server and set the host header to the IP address of EC2 metadata service.
3. The attacker's specially-crafted CURL command is successful, returning the Access Key ID, Secret Access Key, and Session Token of the IAM Instance Profile attached to the EC2 instance.
4. With the IAM role's credentials in hand, the attacker is now able to explore the victim's cloud environment using the powerful permissions granted to the role.
5. The attacker is then able to list, identify, and access a private S3 bucket.
6. Inside the private S3 bucket, the attacker finds several files full of sensitive information, and is able to download these to their local machine for dissemination.

A cheat sheet for this route is available [here](./cheat_sheet.md).
