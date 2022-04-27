#!/bin/bash

if [ $(aws --profile $2 iam list-attached-user-policies --user-name $1 --query  'AttachedPolicies[].PolicyArn' --out text | wc -c) \> 0 ]
then

aws --profile $2 iam list-attached-user-policies --user-name $1 --query  'AttachedPolicies[].PolicyArn' --out text | xargs -n 1 aws --profile $2 iam detach-user-policy --user-name $1 --policy-arn

fi

