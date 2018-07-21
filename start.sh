#!/bin/bash

mkdir -p keys

if [[ -z "./keys/cloudgoat_key" ]]; then
  echo "Creating cloudgoat_key for SSH access."
  ssh-keygen -b 2048 -t rsa -f ./keys/cloudgoat_key -q -N ""
  else echo "cloudgoat key found, skipping creation."
fi

if [[ -n `grep insert_cloudgoat_key terraform/ec2.tf` ]]; then
  echo "Inserting cloudgoat_key into Terraform config for EC2 instance."
  awk 'BEGIN{getline k < "keys/cloudgoat_key.pub"}/insert_cloudgoat_key/{gsub("insert_cloudgoat_key",k)}1' terraform/ec2.tf > ./temp && mv ./temp terraform/ec2.tf
  else echo "Public key found in Terraform config, using the existing key."
fi

if [[ -z `gpg --list-keys | grep Cloudgoat` ]]; then
  echo "Creating PGP key for Cloudgoat use."
  cd keys && gpg --batch --gen-key pgp_options && cd ..
  else echo "Cloudgoat PGP key found, using the existing key."
fi

if [[ -f ./keys/pgp_cloudgoat ]]; then
  echo "Base64 PGP public key conversion file found."
  else echo "Creating base64 PGP public key conversion for Terraform use."
  gpg --export Cloudgoat | base64 >> keys/pgp_cloudgoat
fi

cd terraform && terraform plan -out plan.tfout
terraform apply -auto-approve plan.tfout

./extract_creds.py
