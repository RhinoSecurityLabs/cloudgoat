
# Scenario: bedrock_agent_hijacking

**Size:** Small

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create bedrock_agent_hijacking`

## Scenario Resources

- 1 IAM User
- 1 Lambda Function (+ Execution Role)
- 1 Bedrock Agent (+ Execution Role & Action Group)
- 1 S3 Bucket

## Scenario Start(s)

1. IAM User Grace

## Scenario Goal(s)

Retrieve the Flag Stored in S3.

## Summary

Starting as the IAM user Grace, the attacker discovers that they have limited lambda permissions and can invoke a bedrock agent. Interacting with the agent (or examining its action groups) reveals the agent is leveraging a lambda function to conduct a real-time inventory of cloud resources. The attacker uses their limited lambda permissions to change the function behaviour and has the agent retrieve the flag from S3.

## Exploitation Route(s)

![Scenario Route(s)](https://lucid.app/publicSegments/view/07d01afa-313b-47d0-ab5b-fad1784d48fd/image.png)

## Walkthrough - IAM User "Grace"

1. Starting as the IAM user "Grace",  the attacker analyses their privileges.
2. The attacker realizes they have access to:
   - Limited lambda permissions, including the `lambda:UpdateFunctionCode` permission
   - Bedrock read operations
   - Invocation permissions for the `operations_agent` bedrock agent
3. The attacker looks at the `operations_agent` agent configuration and notices it can invoke the `inventory_lambda` function via an action group.
4. The attacker gets the lambda details using the function ARN found in the agent's action group configuration, noting that it has global read access and can only be invoked by the bedrock service.
5. The attacker crafts a replacement lambda function (that meets the bedrock response event requirements) to either perform S3 discovery or exfiltrate the lambda execution role credentials, and uses `lambda:UpdateFunctionCode` to replace the function code.
6. The attacker converses with the agent, getting it to trigger the lambda function and display the results
7. Attacker uses exfiltrated credentials to access the flag, or repeats steps 5-6 to have the agent retrieve the flag from S3

A cheat sheet for this route is available [here](./cheat_sheet.md).
