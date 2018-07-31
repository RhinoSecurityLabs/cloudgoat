# CloudGoat
Rhino Security Labs' "Vulnerable by Design" AWS infrastructure setup tool

## Requirements
- Python2 or Python3  
- Terraform in your $PATH (https://www.terraform.io/downloads.html)  
- gpg (`apt-get install gpg`)  
- OpenSSH (For SSH key generation)  

## Usage

### How to deploy the CloudGoat environment
1. `git clone https://github.com/RhinoSecurityLabs/cloudgoat.git && cd cloudgoat`  
2. `./start.sh <ip range>` - Where `<ip range>` is an IP range that CloudGoat whitelists access to in every security group, to ensure only you can access the environment.  

Now the credentials to get you started will be stored in ./credentials.txt and if you are starting with access to EC2 or Lightsail, the OpenSSH key is stored in ./keys/  

### How to destroy the CloudGoat environment
1. `./kill.sh`  

## Note about AWS Glue, why it's disabled, and how to re-enable it
- The Glue development endpoint is disabled by default due to it costing far more than the whole rest of CloudGoat to run. If you would like to enable the Glue development endpoint (estimated at $1 per hour), uncomment the final three lines of "start.sh", uncomment the final eight lines of "kill.sh", and uncomment the file located at "./terraform/glue.tf".
