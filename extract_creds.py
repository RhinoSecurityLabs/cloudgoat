#!/usr/bin/env python

import json
import subprocess

with open('./terraform/terraform.tfstate') as tfstate:
  data = json.load(tfstate)

  with open('./credentials.txt', 'a') as credfile:
    encryptpass = data['modules'][0]['resources']['aws_iam_user_login_profile.administrator']['primary']['attributes']['encrypted_password']
    print encryptpass
    echovar = subprocess.Popen(["echo", encryptpass], stdout=subprocess.PIPE)
    decodepass = subprocess.Popen(["base64", "--decode"], stdin=echovar.stdout, stdout=subprocess.PIPE)
    print decodepass.stdout.read()
    clearpass = subprocess.Popen(["gpg", "--decrypt"], stdin=decodepass.stdout, stdout=subprocess.PIPE).stdout.read()
    credfile.write("Administrator Password:   " + clearpass + '\n')
    credfile.write("Bob's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob_key']['primary']['id'] + "\n")
    credfile.write("Bob's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.bob_key']['primary']['attributes']['secret'] + "\n" )
    credfile.write("Joe's Access Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe_key']['primary']['id'] + "\n")
    credfile.write("Joe's Secret Key:         " + data['modules'][0]['resources']['aws_iam_access_key.joe_key']['primary']['attributes']['secret'] + "\n" )
