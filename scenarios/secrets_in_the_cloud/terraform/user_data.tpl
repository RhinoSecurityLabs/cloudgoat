#!/bin/bash

# This Bash/template file:
# - Installs Python3 and Flask
# - Exports the API key, the AWS Access key, and the AWS Secret key
# - Creates two (2) HTML files
#    1. index.html
#    2. admin.html
# - Creates one (1) Python file
#    1. app.py
# - Creates, enables, and starts a web application Systemd service 
# - Installs, configures, and starts the docker service
# - Installs and runs the docker-version of Vault ( a tool to securely store secrets ).
# - Installs the Vault CLI
# - Logs into Vault account
# - Stores an SSH private key into the Vault.

yum update -y
yum install -y python3
pip3 install flask
echo 'API_KEY="DavidsDelightfulDonuts2023"' >> /etc/environment

cat <<-INDEX > /home/ec2-user/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jeff's Paradise</title>
</head>
<body>
    <h1>Welcome to Jeff's Paradise</h1>
    <p><a href="/admin">Jeff's Admin Page</a></p>
</body>
</html>
INDEX

cat <<-ADMIN > /home/ec2-user/admin.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jeff's Admin Page</title>
</head>
<body>
    <h1>Mitch & Ryan's Winter Wonderland</h1>
    <form id="api-key-form">
        <label for="api-key">API Key:</label>
        <input type="text" id="api-key" name="api-key">
        <button type="submit">Submit</button>
    </form>
    <div id="response"></div>

    <script>
        document.getElementById('api-key-form').addEventListener('submit', async (event) => {
            event.preventDefault();
            const apiKey = document.getElementById('api-key').value;
            const responseDiv = document.getElementById('response');
            try {
                const response = await fetch('/api/check-api-key?key=' + apiKey);
                const jsonResponse = await response.json();
                if (jsonResponse.success) {
                    responseDiv.textContent = 'Vault Token: ' + jsonResponse.password;
                } else {
                    responseDiv.textContent = 'Try Harder or something.';
                }
            } catch (error) {
                console.error(error);
                responseDiv.textContent = 'An error occurred. Please try again.';
            }
        });
    </script>
</body>
<!-- Greetings, fellow developers, it's your leader Jeff here. I have a peculiar and exciting task list for y'all, and I'm eager to see what whimsical wonders we can achieve together:
1. Herd those environment variables like they're a flock of wild geese; let's ensure no sensitive data goes on a surprise migration!
2. Tango with the HashiCorp endpoint as if you're on a dance floor; make that API connection a smooth and elegant waltz of efficiency!
3. Transform our cloud security into a mythical beast, part dragon and part unicorn, staying one step ahead of potential threats and maintaining a fortress of enchantment; let's concoct a magical brew of safety and innovation!
Let's blend our collective skills and passion for the extraordinary, my programming pals! To infinity and beyond! -->
</html>
ADMIN

cat <<-APP > /home/ec2-user/app.py
from flask import Flask, request, jsonify, send_from_directory
import os

app = Flask(__name__, static_url_path='', static_folder='.')

API_KEY = os.environ.get('API_KEY')
VAULT_TOKEN = 'TorysTotallyTubular456'

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/admin')
def admin():
    return send_from_directory('.', 'admin.html')

@app.route('/api/check-api-key')
def check_api_key():
    key = request.args.get('key')
    if key is None or key != API_KEY:
        return jsonify(success=False)
    if key == API_KEY:
        return jsonify(success=True, password=VAULT_TOKEN)
    else:
        return jsonify(ERROR)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
APP

chown ec2-user:ec2-user /home/ec2-user/app.py /home/ec2-user/index.html /home/ec2-user/admin.html
chmod +x /home/ec2-user/app.py

cat <<-SERVICE > /etc/systemd/system/webapp.service
[Unit]
Description=Web App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user
EnvironmentFile=/etc/environment
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable webapp
systemctl start webapp

yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Install and configure Vault
docker pull hashicorp/vault
docker run --cap-add=IPC_LOCK -d --name=vault -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=TorysTotallyTubular456' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' hashicorp/vault 

# Install the Vault CLI
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault
export VAULT_ADDR='http://127.0.0.1:8200'

# Log in to Vault and store id_rsa
vault login TorysTotallyTubular456
vault kv put secret/tylers_seekrit value='TylerTantalizingTacosTangleToucans'
vault kv put secret/brads_seekrit value='BradBefriendsBouncingBlueberryBison'
export SSH_PRIVATE_KEY="${private_key}"
vault kv put secret/id_rsa value="$SSH_PRIVATE_KEY"

# Update .bash_profile with hint
cat >> /home/ec2-user/.bash_profile <<-'EOF'
+--------------------------------------------------------------------+
|                                                                    |
| Hey Devs, it's Jeff. Please ensure only IMDSv2 is enabled on the   |
| EC2 instances! Thanks, haha! :)                                    |
|                                                                    |
+--------------------------------------------------------------------+
EOF
