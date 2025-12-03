
# Scenario: agentcore_identity_confusion

**Size:** Medium

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create agentcore_identity_confusion`

## Scenario Resources

- 1 IAM User
- 2 IAM Roles
- 2 S3 Buckets
- 1 Bedrock KnowledgeBase (Backed by an OpenSearch Collection)

## Scenario Start(s)

1. IAM User Sandy

## Scenario Goal(s)

You know your account's Bedrock AgentCore agents have access to sensitive data, but you can't seem to find a way to spin any agent instances up... Using alternate means, find a way to gain access to the Agent Runtime's source of sensitive data.

## Summary

Starting as the IAM user Sandy, the attacker discovers that they have permissions to manage agentcore code interpreters and pass agentcore roles. The attacker realizes that agent runtime roles have the same service trust as code interpreter roles, and creates a code interpreter with the agent runtime role. Then, the attacker starts a code interpreter session and invokes the code interpreter directly to exfiltrate data from the bedrock knowledgebase the agent runtimes have access to. 

## Walkthrough - IAM User "Sandy"

1. Starting as the IAM user "Sandy",  the attacker analyses their privileges.
2. The attacker realizes they have access to:
    - IAM and Bedrock Read Operations
    - `iam:PassRole` for all agentcore roles (there are 2)
    - AgentCore Code Interpreter management permissions
3. The attacker examines the roles they can pass:
   - `agentcore_code_interpreter_role` can access an S3 bucket
   - `agentcore_agent_runtime_role` can access foundation models, invoke code interpreters, and access a knowledgebase
4. (Optional) The attacker creates a code interpreter with `agentcore_code_interpreter_role`, and invokes it to examine the S3 bucket
5. The attacker creates a code interpreter with `agentcore_code_interpreter_role`, and invokes it to examine the KnowledgeBase

A cheat sheet for this route is available [here](./cheat_sheet.md).