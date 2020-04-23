`aws configure --profile raynor`

`aws iam list-attached-user-policies --user-name raynor --profile raynor`

`aws iam list-policy-versions --policy-arn <generatedARN>/cg-raynor-policy --profile raynor`

`aws iam get-policy-version --policy-arn <generatedARN>/cg-raynor-policy --version-id <versionID> --profile raynor`

`aws iam set-default-policy-version --policy-arn <generatedARN>/cg-raynor-policy --version-id <versionID> --profile raynor`
