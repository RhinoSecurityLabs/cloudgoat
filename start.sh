#!/bin/bash

mkdir keys
ssh-keygen -b 2048 -t rsa -f ./keys/cloudgoat_key -q -N ""

awk 'BEGIN{getline k < "keys/cloudgoat_key.pub"}/insert_cloudgoat_key/{gsub("insert_cloudgoat_key",k)}1' terraform/ec2.tf > ./temp && mv ./temp terraform/ec2.tf

cd terraform
terraform plan -out plan.tf
terraform apply -auto-approve plan.tf
