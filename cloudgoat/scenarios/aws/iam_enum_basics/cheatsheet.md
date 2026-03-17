# IAM Enumeration Basics Walkthrough

## Summary
In this scenario, you are provided with the access keys for a user named `bob`. You need to enumerate Bob's IAM permissions using the AWS CLI. The flags are in the format `HSM{text}` (or `HSM...` for alphanumeric restrictions) and are hidden deep within the resource metadata.

## Detailed Walkthrough

### 1. Configure your profile
Start by configuring the provided credentials:
`aws configure --profile cg-bob`

### Flag 1: Find the Managed Policy Description
First, list the attached managed policies to get the ARN:
`aws iam list-attached-user-policies --user-name cg-bob-<cgid> --profile cg-bob`

Next, query the specific policy using the ARN you found to view its description:
`aws iam get-policy --policy-arn arn:aws:iam::<account-id>:policy/cg-flag1-managed-policy-<cgid> --profile cg-bob`
**Flag 1:** Look at the `"Description"` field. `HSM{m4n4g3d_p0l1cy_m4st3r}`

### Flag 2: Find the Inline Policy Statement ID (Sid)
List the inline policies attached directly to Bob:
`aws iam list-user-policies --user-name cg-bob-<cgid> --profile cg-bob`

Now, pull the JSON document for that inline policy:
`aws iam get-user-policy --user-name cg-bob-<cgid> --policy-name cg-flag2-inline-policy-<cgid> --profile cg-bob`
**Flag 2:** Look at the `"Sid"` value in the JSON output. `HSM1nl1n3p0l1cyd1sc0v3r3d`

### Flag 3: Find the Group Path
Check which groups Bob belongs to. The flag is right there in the output!
`aws iam list-groups-for-user --user-name cg-bob-<cgid> --profile cg-bob`
**Flag 3:** Look at the `"Path"` field. `/HSM_gr0up_m3mb3rsh1p_f0und/`

### Flag 4: Enumerate the Assumable Role Tags
List all roles in the account (or filter to find the one associated with the scenario):
`aws iam list-roles --profile cg-bob`

Once you identify the `cg-flag4-role-<cgid>`, query it specifically to see its tags:
`aws iam get-role --role-name cg-flag4-role-<cgid> --profile cg-bob`
**Flag 4:** Look inside the `"Tags"` array for the Flag key. `HSM{r0l3_trus1_f0und}`

### Flag 5: Investigate the Managed Policy Document JSON
You already found the managed policy in step 1. Let's read the actual JSON document to see what it allows. 
First, note the `"DefaultVersionId"` from step 1 (usually `v1`). Then, read the specific policy version:
`aws iam get-policy-version --policy-arn arn:aws:iam::<account-id>:policy/cg-flag1-managed-policy-<cgid> --version-id v1 --profile cg-bob`
**Flag 5:** Look at the `"Resource"` block in the JSON output. `arn:aws:s3:::HSM{s3cr3t_js0n_str1ng}`