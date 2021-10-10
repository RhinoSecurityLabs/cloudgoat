#!/bin/bash

if [ $(aws iam list-attached-user-policies --user-name $1 --query  'AttachedPolicies[].PolicyArn' --out text | wc -c) \> 0 ]
then

aws iam list-attached-user-policies --user-name $1 --query  'AttachedPolicies[].PolicyArn' --out text | xargs -n 1 aws iam detach-user-policy --user-name $1 --policy-arn

fi

