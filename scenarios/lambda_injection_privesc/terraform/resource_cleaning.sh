#!/bin/bash


if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    echo "installing jq"
    sudo apt install jq
    exit
fi



aws iam list-attached-user-policies --user-name $1 | jq '.AttachedPolicies | .[] | .PolicyArn' | xargs -i aws iam detach-user-policy --user-name $1 --policy-arn {}
