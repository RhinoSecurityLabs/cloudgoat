# Scenario: Static

**Size:** Small

**Difficulty:** Moderate

**Command:** `cloudgoat create static`

## Scenario Resources

- 1 EC2 Instance (Web Server + Automated Bot)
- 1 S3 Bucket (Static Assets)
- 1 IAM Role
- 1 IAM Instance Profile
- 1 VPC (Subnet, Security Group, Internet Gateway)

## Scenario Start(s)

1. The Public IP/URL of the "Hacksmarter Internal Portal" (Output by Terraform)

## Scenario Goal(s)

Compromise the web application's supply chain to harvest the credentials of the automated administrator bot.

## Summary

In this scenario, you act as an external attacker visiting a corporate portal. By analyzing the web application, you identify that it loads critical JavaScript libraries from a public S3 bucket. You must discover a misconfiguration in the bucket's permissions, perform a "Supply Chain Attack" by overwriting the library with malicious code, and wait for an internal administrator bot to log in. Your goal is to capture the bot's credentials and exfiltrate them back to the bucket.

## Exploitation Route

1. **Reconnaissance:** User visits Web Server -> Identifies S3 Bucket in Source Code.
2. **Enumeration:** User checks S3 Bucket permissions -> Finds Anonymous Write Access.
3. **Exploitation:** User uploads malicious `auth-module.js` to S3 -> Overwrites legitimate file.
4. **Execution:** Admin Bot visits Web Server -> Loads malicious JS from S3 -> Script steals credentials.
5. **Exfiltration:** Malicious JS writes `loot.txt` back to the S3 Bucket.
6. **Collection:** User downloads `loot.txt` to get the flag.

## Walkthrough - S3 Static Asset Hijacking

1. Access the provided web server URL.
2. Inspect the page source code to identify external scripts loading from an S3 bucket.
3. Use the AWS CLI (with `--no-sign-request`) to list the bucket contents and identify the bucket name.
4. Test the bucket permissions to discover that it allows anonymous `PutObject` access.
5. Create a malicious JavaScript payload (`malicious_auth.js`) designed to capture login forms and exfiltrate the data.
6. Upload your payload to the bucket, overwriting the legitimate `auth-module.js` file.
7. Wait 1-2 minutes for the automated "Victim Bot" to visit the page and attempt to log in.
8. Check the S3 bucket for a new `loot.txt` file containing the stolen credentials.

A detailed cheat sheet & walkthrough for this route is available [here](./cheat_sheet.md).