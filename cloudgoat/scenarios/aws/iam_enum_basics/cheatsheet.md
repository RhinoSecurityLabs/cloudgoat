### 1\. Configure Your Profile

Before you can interact with the AWS environment, you need to authenticate. As a pentester, you will often juggle multiple compromised keys. Instead of overwriting your default credentials, it is best practice to set up an isolated profile.

When you deploy the scenario, CloudGoat prints Bob's Access Key and Secret Key to your terminal. Use them to configure a new profile specifically for him:

```
aws configure --profile cg-bob

```

*(Leave the default region and output format blank, or set them to us-east-1 and json)*

### Flag 1: Map Out Managed Policies (The Description)

**The Concept:** Managed policies are standalone JSON rulebooks created by administrators. They can be attached to multiple users, groups, or roles at the same time. **The Attack Path:** We need to see which of these rulebooks apply to Bob.

First, ask AWS to list all the managed policies attached to Bob. This will return a list of ARNs (Amazon Resource Names):

```
aws iam list-attached-user-policies --user-name cg-bob-<cgid> --profile cg-bob

```

*Note: You will see IAMReadOnlyAccess (which allows you to play this game) and a custom scenario policy.*

The list command only gives you the names. To see the metadata associated with the custom policy, you have to run a get command using the ARN you just discovered:

```
aws iam get-policy --policy-arn arn:aws:iam::<account-id>:policy/cg-flag1-managed-policy-<cgid> --profile cg-bob

```

**Flag 1:** Look at the "Description" field in the output. `HSM{m4n4g3d_p0l1cy_m4st3r}`

### Flag 2: Hunt for Inline Policies (The Statement ID)

**The Concept:** Unlike managed policies, inline policies are custom, one-off rules baked directly into a specific user. Administrators often create these for quick fixes and then forget about them, making them prime targets for privilege escalation.

First, check if Bob has any hidden inline policies:

```
aws iam list-user-policies --user-name cg-bob-<cgid> --profile cg-bob

```

Now that you have the name of the inline policy, pull the actual JSON document to see what it allows:

```
aws iam get-user-policy --user-name cg-bob-<cgid> --policy-name cg-flag2-inline-policy-<cgid> --profile cg-bob

```

**Flag 2:** In AWS JSON policies, the "Sid" stands for Statement ID, an optional identifier for the rule. Look at the "Sid" value here. `HSM1nl1n3p0l1cyd1sc0v3r3d`

### Flag 3: Investigate Group Memberships (The Path)

**The Concept:** In AWS, you don't just get permissions from policies attached directly to you; you also inherit all permissions from any groups you belong to.

Check which groups Bob is a member of:

```
aws iam list-groups-for-user --user-name cg-bob-<cgid> --profile cg-bob

```

**Flag 3:** AWS organizes resources using a hierarchical "Path". Notice the custom path structure used for this group. `/HSM_gr0up_m3mb3rsh1p_f0und/`

### Flag 4: Identify Assumable Roles (The Tags)

**The Concept:** Roles are temporary "hats" that a user can put on to gain different privileges. If a pentester finds an overly permissive role that their compromised user is allowed to assume, it's often game over.

List all the roles in the AWS account to see what targets exist:

```
aws iam list-roles --profile cg-bob

```

Once you identify the custom scenario role (`cg-flag4-role-<cgid>`), query it specifically to investigate its metadata and see if the administrators left any useful AWS Tags:

```
aws iam get-role --role-name cg-flag4-role-<cgid> --profile cg-bob

```

**Flag 4:** Look inside the "Tags" array. `HSM-r0l3_trus1_f0und-FLAG`

### Flag 5: Deep Dive into Managed Policy Documents (The Target Resource)

**The Concept:** In Step 1, you viewed the *metadata* of the managed policy, but you didn't see the actual JSON rules. AWS handles managed policies uniquely: to allow for rollbacks, AWS saves multiple versions of a policy. To read the rules, you must request a specific version.

First, look back at your output from Step 1 and note the "DefaultVersionId" (it is usually v1).

Now, command AWS to show you the exact JSON document for that default version:

```
aws iam get-policy-version --policy-arn arn:aws:iam::<account-id>:policy/cg-flag1-managed-policy-<cgid> --version-id v1 --profile cg-bob

```

**Flag 5:** Policies define *what* you can do to *which target*. Look at the "Resource" block in the JSON output to see what this policy allows access to. `arn:aws:s3:::HSM{s3cr3t_js0n_str1ng}`