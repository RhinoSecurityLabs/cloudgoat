# IAM Enumeration Basics Walkthrough

## Summary

In this scenario, you start with the access keys for a user named `bob`. Your goal is to manually enumerate Bob's IAM permissions using the AWS CLI to discover five distinct flags hidden deep within the resource metadata. 

The flags generally follow the format `HSM{text}` (with slight variations to bypass AWS character constraints on certain fields).

## Detailed Walkthrough

### 1. Configure your profile
When you deploy the scenario, CloudGoat will print Bob's Access Key and Secret Key directly to your terminal. Use those to configure a new AWS CLI profile:

```bash
aws configure --profile cg-bob
```
*(Leave default region and output format blank or set to `us-east-1` and `json`)*

### Flag 1: Find the Managed Policy Description
Managed policies are standalone policies attached to the user. First, list them to get the exact ARN:

```bash
aws iam list-attached-user-policies --user-name cg-bob-<cgid> --profile cg-bob
```

Next, query the specific policy using the ARN you just found to view its detailed metadata, including its description:

```bash
aws iam get-policy --policy-arn arn:aws:iam::<account-id>:policy/cg-flag1-managed-policy-<cgid> --profile cg-bob
```
**Flag 1:** Look at the `"Description"` field. `HSM{m4n4g3d_p0l1cy_m4st3r}`

### Flag 2: Find the Inline Policy Statement ID (Sid)
Inline policies are directly embedded in the user. List them using:

```bash
aws iam list-user-policies --user-name cg-bob-<cgid> --profile cg-bob
```

Now, pull the JSON document for that inline policy:

```bash
aws iam get-user-policy --user-name cg-bob-<cgid> --policy-name cg-flag2-inline-policy-<cgid> --profile cg-bob
```
**Flag 2:** Look at the `"Sid"` value inside the JSON document. `HSM1nl1n3p0l1cyd1sc0v3r3d`

### Flag 3: Find the Group Path
Permissions can flow down from groups. Check which groups Bob belongs to. (The flag is right there in the output!)

```bash
aws iam list-groups-for-user --user-name cg-bob-<cgid> --profile cg-bob
```
**Flag 3:** Look at the `"Path"` field. `/HSM_gr0up_m3mb3rsh1p_f0und/`

### Flag 4: Enumerate the Assumable Role Tags
Roles allow users to temporarily assume different privileges. List all roles in the account:

```bash
aws iam list-roles --profile cg-bob
```

Once you identify the scenario role (`cg-flag4-role-<cgid>`), query it specifically to see its tags:

```bash
aws iam get-role --role-name cg-flag4-role-<cgid> --profile cg-bob
```
**Flag 4:** Look inside the `"Tags"` array for the Flag key. `HSM-r0l3_trus1_f0und-FLAG`

### Flag 5: Investigate the Managed Policy Document JSON
You already found the managed policy in step 1. Let's read the actual JSON document to see what permissions it explicitly grants. 

First, note the `"DefaultVersionId"` from the step 1 output (usually `v1`). Then, read that specific policy version:

```bash
aws iam get-policy-version --policy-arn arn:aws:iam::<account-id>:policy/cg-flag1-managed-policy-<cgid> --version-id v1 --profile cg-bob
```
**Flag 5:** Look at the `"Resource"` block in the JSON output. `arn:aws:s3:::HSM{s3cr3t_js0n_str1ng}`