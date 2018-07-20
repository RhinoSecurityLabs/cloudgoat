#!/bin/bash

mkdir keys
ssh-keygen -b 2048 -t rsa -f ./keys/cloudgoat_key -q -N ""

#cd terraform
#terraform plan -out plan.tf
#terraform apply -auto-approve plan.tf
