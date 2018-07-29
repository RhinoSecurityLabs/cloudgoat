#!/bin/bash

cd terraform && terraform destroy -auto-approve
rm ../allow_cidr.txt
rm ../credentials.txt
rm ./terraform.tfstate*
rm ./plan.tfout
