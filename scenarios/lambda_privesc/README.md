
# Scenario: lambda_privesc

**Size:** Small  
**Difficulty:** Easy

**Command:** `$ ./cloudgoat.py create lambda_privesc`

## Scenario Resources

1 IAM User  
2 IAM Roles  

## Scenario Start(s)

1. IAM User Chris  

## Scenario Goal(s)

Acquire full admin privileges.
## Summary

Starting as the IAM user Chris, the attacker discovers that they can assume a role that has full Lambda access and pass role permissions. The attacker can then perform privilege escalation to obtain full admin access.  

Note: This scenario may require you to create some AWS resources, and because CloudGoat can only manage resources it creates, you should remove them manually before running `./cloudgoat destroy`.

## Exploitation Route(s)

![Scenario Route(s)](https://app.lucidchart.com/publicSegments/view/f1b7a749-dee0-4645-b305-add2a025b9cc/image.png)


## Walkthrough - IAM User "Chris"

1. Starting as the IAM user "Chris",  the attacker analyses their privileges.
2. The attacker realizes they are able to list and assume IAM roles. There are two interesting IAM roles: lambdaManager and debug.
3. The attacker looks at the attached policies for the two IAM roles and realizes lambdaManager has full lambda access and pass role permissions and the debug role has full administrator privileges.
4. The attacker then tries to assume each role but realizes that they only have sufficient privileges to assume the lambdaManager role, and that the debug role can only be assumed by a Lambda function.
5. The attacker now leverages the lambdaManager role to perform a privilege escalation using a Lambda function.
6. First, the attacker writes a script that will attach the administrator policy to the IAM user "Chris".
7. Next, using the lambdaManager role, the attacker creates a Lambda function, specifying the code in step 6, and set the lambda execution role to the debug role.
8. Lastly, using the lambdaManager role, the attacker invokes the Lambda function, causing the administrator policy to be attached to the "Chris" user and thus gaining full admin access.

A cheat sheet for this route is available [here](./cheat_sheet_chris.md).
