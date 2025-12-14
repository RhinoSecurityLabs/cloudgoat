# ec2.tf

# 1. ELASTIC IP
resource "aws_eip" "web_ip" {
  instance = aws_instance.instance.id
  domain   = "vpc"
}

# 2. AMI LOOKUP
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 3. EC2 INSTANCE
resource "aws_instance" "instance" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id            = aws_subnet.subnet.id
  
  # No SSH Key needed

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  # User Data: We use EOT for the outer wrapper to avoid conflicts
  user_data = <<-EOT
    #!/bin/bash
    set -x

    # --- PHASE 1: WEB SERVER ---
    yum update -y
    yum install -y httpd aws-cli
    
    # Remove default welcome page
    rm -f /etc/httpd/conf.d/welcome.conf
    
    systemctl start httpd
    systemctl enable httpd
    
    # Write LOGIN.HTML
cat <<EOF > /var/www/html/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hacksmarter Portal | Employee Login</title>
    <script src="https://${aws_s3_bucket.assets_bucket.id}.s3.amazonaws.com/auth-module.js"></script>
    <style>
        body { background: #f0f2f5; font-family: 'Segoe UI', sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .login-card { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); width: 350px; text-align: center; }
        input { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        button { width: 100%; padding: 10px; background-color: #00ff41; color: black; border: none; font-weight: bold; cursor: pointer; border-radius: 4px; }
        button:hover { background-color: #00cc33; }
        h2 { color: #333; margin-bottom: 20px; }
        .logo { width: 60px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="login-card">
        <img src="https://${aws_s3_bucket.assets_bucket.id}.s3.amazonaws.com/logo.svg" class="logo">
        <h2>Employee Login</h2>
        <input type="text" id="username" placeholder="Username">
        <input type="password" id="password" placeholder="Password">
        <button id="login-btn">Sign In</button>
        <p style="margin-top:20px; color:#888; font-size:12px;">Authorized Personnel Only</p>
    </div>
</body>
</html>
EOF

    # Write INDEX.HTML (Redirect)
    echo '<meta http-equiv="refresh" content="0; url=/login.html" />' > /var/www/html/index.html
    
    # Fix Permissions
    chown -R apache:apache /var/www/html/
    chmod -R 644 /var/www/html/
    systemctl restart httpd

    # --- PHASE 2: THE VICTIM BOT ---
    amazon-linux-extras install epel -y
    yum install -y chromium chromedriver python3-pip
    pip3 install selenium

    # Write BOT SCRIPT
cat <<EOF > /home/ec2-user/victim_bot.py
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import time

def run_bot():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    driver = webdriver.Chrome(options=chrome_options)
    
    try:
        driver.get("http://localhost/login.html")
        
        user_field = driver.find_element(By.ID, "username")
        pass_field = driver.find_element(By.ID, "password")
        btn = driver.find_element(By.ID, "login-btn")
        
        user_field.send_keys("tyler")
        pass_field.send_keys("H@cKallth3th!ngs!3")
        
        btn.click()
        
        time.sleep(5)
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    while True:
        run_bot()
        time.sleep(30)
EOF

    # Write SERVICE
cat <<EOF > /etc/systemd/system/victim_bot.service
[Unit]
Description=CloudGoat Victim Bot
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /home/ec2-user/victim_bot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start victim_bot
    systemctl enable victim_bot
  EOT

  tags = {
    Name = "cg-webserver-${var.cgid}"
    Stack = var.stack_name
    Scenario = var.scenario_name
  }
}

# 4. SECURITY GROUP
resource "aws_security_group" "sg" {
  name        = "cg-sg-${var.cgid}"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}