Scenario: lambda_injection_privesc
Size: Small
Difficulty: Easy

Command: $ ./cloudgoat.py create lambda_injection_privesc

Scenario Resources
1 IAM User
1 IAM Role
1 Lambda
1 Secret

Scenario Start(s)
IAM User 'bilbo'
Scenario Goal(s)
Find the scenario's secret. (cg-secret-XXXXXX-XXXXXX)

Summary
In this scenario, you start as the 'bilbo' user. You will assume a role with more privelages, discover a lambda function that applies policies to users, and exploit a vulnerability in the function to escalate the privelages of the bilbo user in order to search for secrets.

Exploitation Route
Lucidchart Diagram

Walkthrough - IAM User "bilbo"
Get permissions for the 'bilbo' user.
List all roles.
List lambdas to identify the target lambda.
Look at the lambda source code.
Assume the lambda invoker role.
Craft an injection payload to send through the CLI.
Base64 encode that payload. The single quote injection character is not compatible with the aws cli command otherwise.
Invoke the policy applier lambda function, passing the name of the bilbo user and the injection payload.
Now that Bilbo is an admin, use credentials for that user to list secrets from secretsmanager.
A cheat sheet for this route is available here.