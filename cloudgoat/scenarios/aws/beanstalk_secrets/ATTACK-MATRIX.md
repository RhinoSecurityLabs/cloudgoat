### Scenario: `beanstalk_secrets`

**Description:**  
An attacker with low-privileged AWS credentials enumerates Elastic Beanstalk environments, extracts IAM credentials from misconfigured environment variables, escalates privileges by creating access keys for an admin user, and finally retrieves sensitive data from AWS Secrets Manager.

| Tactic              | Technique ID | Technique Name                                         | Justification                                                                                 |
|---------------------|--------------|--------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| Initial Access       | T1078.004    | Valid Accounts: Cloud Accounts                         | The scenario starts with pre-existing IAM credentials for a low-privileged user.              |
| Discovery            | T1526        | Cloud Service Discovery                                | Elastic Beanstalk environments are enumerated via `elasticbeanstalk__enum`.                  |
| Credential Access    | T1552.001    | Unsecured Credentials: Environment Variables           | IAM credentials are exposed via Elastic Beanstalk environment variables.                      |
| Discovery            | T1087.004    | Account Discovery: Cloud Account                       | IAM users and roles are enumerated using secondary credentials to identify admin.             |
| Privilege Escalation | T1098.001    | Account Manipulation: Create Account Access Key        | `iam:CreateAccessKey` is used to generate credentials for an administrator user.              |
| Collection           | T1555        | Credentials from Password Stores                       | Secrets are retrieved from AWS Secrets Manager using admin-level credentials.                 |
