`aws configure --profile raynor`

`aws sts get-caller-identity --profile raynor`

`aws iam list-attached-user-policies --user-name <username-raynor> --profile raynor`

`aws iam list-policy-versions --policy-arn <cg-raynor-policy arn> --profile raynor`

`aws iam get-policy-version --policy-arn <cg-raynor-policy arn> --version-id <versionID> --profile raynor`

`aws iam set-default-policy-version --policy-arn <cg-raynor-policy arn> --version-id <versionID> --profile raynor`
