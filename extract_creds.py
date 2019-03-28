#!/usr/bin/env python

import json
import subprocess

with open('./terraform/terraform.tfstate') as tfstate:
  data = json.load(tfstate)

  with open('./credentials.txt', 'w') as credfile:
    encryptpass = data['modules'][0]['resources']['aws_iam_user_login_profile.administrator']['primary']['attributes']['encrypted_password']
    echovar = subprocess.Popen(["echo", encryptpass], stdout=subprocess.PIPE)
    decodepass = subprocess.Popen(["base64", "--decode"], stdin=echovar.stdout, stdout=subprocess.PIPE)
    clearpass = subprocess.Popen(["gpg", "--decrypt"], stdin=decodepass.stdout, stdout=subprocess.PIPE).stdout.read().decode("utf-8")
    credfile.write("Administrator Password:   " + clearpass + '\n')
    credfile.write("Bob's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob_key']['primary']['id'] + "\n")
    credfile.write("Bob's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe_key']['primary']['id'] + "\n")
    credfile.write("Joe's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe_key']['primary']['attributes']['secret'] + "\n" )

# Uncomment the follow two lines if you are enabling the Glue development endpoint (along with start.sh, kill.sh, and terraform/glue.tf
#  with open('./tmp/glue_role_arn.txt', 'w+') as glue_file:
#    glue_file.write(data['modules'][0]['resources']['aws_iam_role.glue_dev_endpoint']['primary']['attributes']['arn'])
