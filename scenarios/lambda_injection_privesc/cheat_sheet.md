1. Get permissions for the 'bilbo' user.

    ```bash
    # This command will give you the ARN & full name of you user.
    aws --profile bilbo --region us-east-1 sts get-caller-identity
    # This command will list the policies attached to your user.
    aws --profile bilbo --region us-east-1 iam list-user-policies --user-name [your_user_name]
    # This command will list all of your permissions.
    aws --profile bilbo --region us-east-1 iam get-user-policy --user-name [your_user_name] --policy-name [your_policy_name]
    ```
2. List all roles, assume a role for privesc.

    ```bash
    # This command will list all the roles in your account, one of which should be assumable. 
    aws --profile bilbo --region us-east-1 iam list-roles
    # This command will get you credentials for the cloudgoat role that can invoke lambdas.
    aws --profile bilbo --region us-east-1 sts assume-role --role-arn [cg-lambda-invoker_arn] --role-session-name [whatever_you_want_here]

    ```
3. List lambdas to identify the target lambda.

    ```bash
    # This command will show you two cloudgoat functions. One function is the target function that you need
    # to invoke in order to finish this scenario. The other function can apply a predefined set of
    # aws managed policies to users (in reality it can only modify the bilbo user).
    aws --profile assumed_role --region us-east-1 lambda list-functions
    ```
4. Look at the lambda source code.

    ```bash
    # This command will download the source code for the lambda that can apply policies to bilbo.
    ```
5. Assume the lambda invoker role.

    ```bash
    echo "this is a bash command"
    ```
6. Craft an injection payload to send through the CLI.

    ```bash
    echo "this is a bash command"
    ```
7. Base64 encode that payload. The single quote injection character is not compatible with the aws cli command otherwise.

    ```bash
    echo "this is a bash command"
    ```
8. Invoke the role applier lambda function, passing the name of the bilbo user and the injection payload. 

    ```bash
    echo "this is a bash command"
    ```
9. Now that Bilbo is an admin, use credentials for that user to invoke the target lambda. 

    ```bash
    echo "this is a bash command"
    ```