#!/bin/bash

mkdir -p keys

allowcidr=$1

printf $allowcidr > allow_cidr.txt

cloudgoat_public_bucket_name=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
cloudgoat_private_bucket_name=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)

echo $allowcidr
if [[ ! -f ./keys/cloudgoat_key ]]; then
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

if [[ -f "terraform/plan.tfout" ]]; then
   rm terraform/plan.tfout
fi

cd terraform && terraform init && terraform plan -var cloudgoat_private_bucket_name=$cloudgoat_private_bucket_name -var cloudgoat_public_bucket_name=$cloudgoat_public_bucket_name -var ec2_public_key="`cat ../keys/cloudgoat_key.pub`" -out plan.tfout
terraform apply -auto-approve plan.tfout

cd .. && ./extract_creds.py
