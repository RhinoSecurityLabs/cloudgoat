#!/bin/sh

aws iam list-attached-user-policies --user-name $1 | jq '.AttachedPolicies | .[] | .PolicyArn' | xargs -i aws iam detach-user-policy --user-name $1 --policy-arn {}
