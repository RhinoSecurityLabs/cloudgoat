1. Get permissions for the 'bilbo' user.

    ```bash
    echo "this is a bash command"
    ```
2. List all roles.
3. List lambdas to identify the target lambda.
4. Look at the lambda source code.
5. Assume the lambda invoker role.
6. Craft an injection payload to send through the CLI.
7. Base64 encode that payload. The single quote injection character is not compatible with the aws cli command otherwise.
8. Invoke the role applier lambda function, passing the name of the bilbo user and the injection payload. 
9. Now that Bilbo is an admin, use credentials for that user to invoke the target lambda. 