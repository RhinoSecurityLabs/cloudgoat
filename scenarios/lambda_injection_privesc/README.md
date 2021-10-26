
# Scenario: lambda_injection_privesc

**Size:** Small  
**Difficulty:** Easy

**Command:** `$ ./cloudgoat.py create lambda_injection_privesc`

## Scenario Resources

1 IAM User  
1 IAM Role  
2 Lambdas 

## Scenario Start(s)

1. IAM User 'bilbo' 

## Scenario Goal(s)

Invoke the target lambda. (cgid-target_lambda)

## Summary

In this scenario, you start as the 'bilbo' user. You will assume a role with more privelages, discover a 
lambda function that applies policies to users, and exploit a vulnerability in the function to escelate 
the privelages of the bilbo user. 

## Exploitation Route

![Lucidchart Diagram](exploitation_route.png "Exploitation Route")


## Walkthrough - IAM User "bilbo"

1. Get permissions for the 'bilbo' user.
2. List all roles.
3. List lambdas to identify the target lambda.
4. Look at the lambda source code.
5. Assume the lambda invoker role.
6. Craft an injection payload to send through the CLI.
7. Base64 encode that payload. The single quote injection character is not compatible with the aws cli command otherwise.
8. Invoke the policy applier lambda function, passing the name of the bilbo user and the injection payload. 
9. Now that Bilbo is an admin, use credentials for that user to invoke the target lambda. 

A cheat sheet for this route is available [here](./cheat_sheet.md).