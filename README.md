# CloudGoat
Rhino Security Labs' "Vulnerable by Design" AWS infrastructure setup tool

## Requirements
- Linux/MacOS
- Python2 or Python3  
- Terraform in your $PATH (https://www.terraform.io/downloads.html)  
- gpg (`apt-get install gpg`)  
- OpenSSH (For SSH key generation)  

## Warning
- **CloudGoat deploys intentionally vulnerable AWS resources into your account. DO NOT deploy CloudGoat in a production environment or alongside any sensitive AWS resources.**  

## Usage

### How to deploy the CloudGoat environment
Note: CloudGoat uses the credentials that are setup as the "default" profile for the AWS CLI (Usually stored under `~/.aws/credentials`, with the "[default]" header). You can set/change these keys by running the AWS CLI command `aws configure`.  
1. `git clone https://github.com/RhinoSecurityLabs/cloudgoat.git && cd cloudgoat`  
2. `./start.sh <ip range>` - Where `<ip range>` is an IP range that CloudGoat whitelists access to in every security group, to ensure only you can access the environment.  

Now the credentials to get you started will be stored in ./credentials.txt and if you are starting with access to EC2 or Lightsail, the OpenSSH key is stored in ./keys/  

### How to destroy the CloudGoat environment
1. `./kill.sh`  

## Note about AWS Glue, why it's disabled, and how to re-enable it
- The Glue development endpoint is disabled by default due to it costing far more than the whole rest of CloudGoat to run. If you would like to enable the Glue development endpoint (estimated at $1 per hour), uncomment the relevant lines in "start.sh", "kill.sh", "extract_creds.py", and "./terraform/glue.tf".
- The AWS CLI you have installed must be using at least version 1.12.79 of botocore or else the development endpoint will fail to launch, due to an API change.

## Changelog
- **1/16/19:** Fixed a bug when using the Glue Development Endpoint where the CloudGoat SSH key was not being added.
- **8/29/18:** Added a few permissions to Bob so that it is no longer required to bruteforce permissions (or cheat) to gain further access.
- **8/6/18:** Fixed `tr: Illegal byte sequence` error on Mac operating systems.
- **8/1/18:** Modified `extract_creds.py` to fix support for Python3.
- **7/31/18:** Public GitHub release!
