#!/bin/bash
yum update -y
yum install -y python3
pip3 install flask
echo 'API_KEY="DavidsDelightfulDonuts2023"' >> /etc/environment
export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

cat <<-INDEX > /home/ec2-user/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudGoat Web App</title>
</head>
<body>
    <h1>Welcome to CloudGoat Web App</h1>
    <p><a href="/admin">Big Time Admin Page</a></p>
</body>
</html>
INDEX

cat <<-ADMIN > /home/ec2-user/admin.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mitch's Admin Page</title>
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
<!-- Hahaha! Hey, devs, it's Jeff, BIG JAY IN THE BUILDING YA'LL WOOO! I've got a fantastic TODO list for you, and I can barely contain my laughter:
1. Sweep away those sensitive environment variables; we don't want any surprises!
2. Supercharge those database queries; efficiency is our middle name
3. Refine the CSS for pristine readability; let's keep it top-notch
4. Fortify error handling for API requests; no room for errors, haha!
5. Put new features to the test; we demand the highest quality
6. Maintain flawless documentation; it's the beacon that guides us
Let's keep up the good work, team! Hahaha! -->
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
docker pull vault
docker run --cap-add=IPC_LOCK -d --name=vault -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=TorysTotallyTubular456' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' vault

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
