# ec2.tf

# 1. ELASTIC IP
resource "aws_eip" "web_ip" {
  instance = aws_instance.instance.id
  domain   = "vpc"
}

# 3. AMI LOOKUP
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 4. EC2 INSTANCE
resource "aws_instance" "instance" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id            = aws_subnet.subnet.id
  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  # IMPORTANT: The markers (HTML_END, PYTHON_END) below are flushed left.
  # Do not add spaces before them!
  user_data = <<-EOF
    #!/bin/bash
    set -x

    # --- PHASE 1: WEB SERVER ---
    yum update -y
    yum install -y httpd aws-cli
    systemctl start httpd
    systemctl enable httpd
    
    # Create the website content
    # We use double quotes around EOF to prevent shell expansion, 
    # but Terraform will still swap in the Bucket ID.
cat << "HTML_END" > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hacksmarter Portal</title>
    <script src="https://${aws_s3_bucket.assets_bucket.id}.s3.amazonaws.com/ui-interactions.js"></script>
    <style>
        body { background: #1a1a1a; color: #00ff41; font-family: monospace; padding: 50px; text-align: center; }
        h1 { font-size: 40px; }
        .logo { width: 100px; }
    </style>
</head>
<body>
    <img src="https://${aws_s3_bucket.assets_bucket.id}.s3.amazonaws.com/logo.svg" class="logo">
    <h1>Hacksmarter Internal</h1>
    <p>Admin bot visits every minute...</p>
</body>
</html>
HTML_END

    chown apache:apache /var/www/html/index.html
    chmod 644 /var/www/html/index.html

    # --- PHASE 2: THE VICTIM BOT ---
    amazon-linux-extras install epel -y
    yum install -y chromium chromedriver python3-pip
    pip3 install selenium

    # Create the Bot Script
cat << "PYTHON_END" > /home/ec2-user/victim_bot.py
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time

def run_bot():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    driver = webdriver.Chrome(options=chrome_options)
    
    try:
        # 1. Visit site
        driver.get("http://localhost")
        
        # 2. Add the SECRET FLAG cookie
        driver.add_cookie({"name": "session_token", "value": "CG{xss_to_s3_exfiltration_master}", "path": "/"})
        
        # 3. Refresh so the cookie is sent
        driver.refresh()
        
        # 4. Wait for XSS
        time.sleep(5)
    except Exception as e:
        print(f"Error: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    while True:
        run_bot()
        time.sleep(30)
PYTHON_END

    # Create Service
cat << "SERVICE_END" > /etc/systemd/system/victim_bot.service
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
SERVICE_END

    systemctl daemon-reload
    systemctl start victim_bot
    systemctl enable victim_bot
  EOF

  tags = {
    Name = "cg-webserver-${var.cgid}"
    Stack = var.stack-name 
    Scenario = var.scenario-name
  }
}

# 5. SECURITY GROUP
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