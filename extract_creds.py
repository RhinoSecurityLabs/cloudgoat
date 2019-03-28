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
    credfile.write("Bob1's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob1_key']['primary']['id'] + "\n")
    credfile.write("Bob1's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob1_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe1's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe1_key']['primary']['id'] + "\n")
    credfile.write("Joe1's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe1_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Bob2's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob2_key']['primary']['id'] + "\n")
    credfile.write("Bob2's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob2_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe2's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe2_key']['primary']['id'] + "\n")
    credfile.write("Joe2's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe2_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Bob3's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob3_key']['primary']['id'] + "\n")
    credfile.write("Bob3's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob3_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe3's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe3_key']['primary']['id'] + "\n")
    credfile.write("Joe3's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe3_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Bob4's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob4_key']['primary']['id'] + "\n")
    credfile.write("Bob4's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob4_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe4's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe4_key']['primary']['id'] + "\n")
    credfile.write("Joe4's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe4_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Bob5's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob5_key']['primary']['id'] + "\n")
    credfile.write("Bob5's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob5_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe5's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe5_key']['primary']['id'] + "\n")
    credfile.write("Joe5's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe5_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Bob6's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob6_key']['primary']['id'] + "\n")
    credfile.write("Bob6's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob6_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe6's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe6_key']['primary']['id'] + "\n")
    credfile.write("Joe6's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe6_key']['primary']['attributes']['secret'] + "\n" )

# Uncomment the follow two lines if you are enabling the Glue development endpoint (along with start.sh, kill.sh, and terraform/glue.tf
#  with open('./tmp/glue_role_arn.txt', 'w+') as glue_file:
#    glue_file.write(data['modules'][0]['resources']['aws_iam_role.glue_dev_endpoint']['primary']['attributes']['arn'])
