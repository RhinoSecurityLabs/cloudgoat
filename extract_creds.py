#!/usr/bin/env python

import json
import gnupg

with open('./terraform/terraform.tfstate') as tfstate:
  data = json.load(tfstate)

  with open('./credentials.txt', 'a') as credfile:
    adminpass = data['modules'][0]['resources']['aws_iam_user_login_profile.administrator']['primary']['attributes']['encrypted_password']
    credfile.write("Administrator Password:   " + adminpass + '\n'
    credfile.write("Bob's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob_key']['primary']['id'] + "\n")
    credfile.write("Bob's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe_key']['primary']['id'] + "\n")
    credfile.write("Joe's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe_key']['primary']['attributes']['secret'] + "\n" )
