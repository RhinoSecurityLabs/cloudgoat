#!/usr/bin/env python3
import argparse, boto3, base64

parser = argparse.ArgumentParser(description='This script will deploy resources associated with the vulnerable-by-design AWS environment. The environment is meant to be used as a vulnerable-by-design testing environment for discovering and abusing AWS misconfigurations to escalate privileges, exfiltrate data, discover secrets, and more.', epilog='Written by Spencer Gietzen of Rhino Security Labs. Visit HERE for a blog post that goes in depth on this vulnerable AWS environment.')

parser.add_argument('--access-key', required=True, help='The Access Key ID of the AWS account to deploy in.')
parser.add_argument('--ip', required=True, help='The IP address to whitelist for resources that support it, such as EC2 instances. This ideally should be your own personal IP address, so that only you are able to access the vulnerable resources.')
parser.add_argument('--secret-key', required=True, help='The Secret Key of the AWS account to deploy in.')
parser.add_argument('--region', required=False, default='us-east-1', help='The AWS region to deploy in. The default is us-east-1.')


def main(args):
    web_server_pass = 'randomly-generated'
    mike_user_pass = ''
    datacollector_user_pass = ''
    admin_user_pass = ''

    ec2_userdata = bytes('#cloud-boothook\n#!/bin/sh\napt-get update\napt-get install php -y\napt-get install python apache2 -y\napt-get install libapache2-mod-php7.0 -y\na2enmod php7.0\nmkdir -p /var/www/html\ncd /var/www/html\nrm -rf ./*\nprintf "<RequireAll>\\n    Require ip {}\\n</RequireAll>" >> .htaccess\nprintf "<?php\\nif(isset(\\$_POST[\'folder\'])) {{\\n  if(strcmp(\\$_POST[\'password\'], \'{}\') != 0) {{\\n    echo \'Wrong password. You just need to find it!\';\\n    die;\\n  }}\\n  echo \'<pre>\';\\n  system(\'ls \'.\\$_POST[\'folder\']);\\n  echo \'</pre>\';\\n  die;\\n}}\\n?>\\n<html><head><title>Folder Viewer</title></head><body><form method=\'POST\'><label for=\'folder\'>Enter the password and a path to a folder that you want to view the contents of (ex: /tmp)</label><br /><input type=\'text\' name=\'password\' placeholder=\'Password\' /><input type=\'text\' name=\'folder\' placeholder=\'Folder\' /><br /><input type=\'submit\' value=\'Display Contents\' /></form></body></html>" >> index.php\nservice apache2 start\n\npassword={}'.format(args.ip, web_server_pass, web_server_pass), 'utf-8')
    #print(ec2_userdata)

    ec2_userdata = base64.b64encode(ec2_userdata)
    print(ec2_userdata)

    #ec2_userdata = base64.b64decode(ec2_userdata)
    #print(ec2_userdata.decode('utf-8'))

    cf_template_file = open('./vuln.template', 'r')
    cf_template = cf_template_file.read()
    cf_template_file.close()


    # 1: Generate secrets and passwords that get inserted to the CloudFormation template
    # 2: Deploy the CloudFormation Template
    # 3: Save the access keys/passwords for each user in .txt files
    # 4: Create CloudTrail trail with max rules

if __name__ == '__main__':
    args = parser.parse_args()
    main(args)