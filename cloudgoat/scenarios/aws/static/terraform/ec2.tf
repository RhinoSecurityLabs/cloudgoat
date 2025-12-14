# ec2.tf

# 1. AMI LOOKUP
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
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = aws_subnet.subnet.id
  associate_public_ip_address = true
  
  key_name                    = aws_key_pair.ec2_key.key_name

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  # USER DATA: Installs Apache and writes a realistic "Hacksmarter" landing page
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd aws-cli
    systemctl start httpd
    systemctl enable httpd
    
    # Create the website content
    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Hacksmarter | Advanced Cloud Security Training</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #1a1a1a; color: #f0f0f0; margin: 0; padding: 0; }
            header { background-color: #0d0d0d; padding: 20px 40px; display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #00ff41; }
            h1 { margin: 0; font-size: 24px; color: #00ff41; letter-spacing: 1px; text-transform: uppercase; }
            nav a { color: #fff; text-decoration: none; margin-left: 20px; font-weight: bold; font-size: 14px; }
            nav a:hover { color: #00ff41; }
            .hero { padding: 80px 40px; text-align: center; background: linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.7)); }
            .hero h2 { font-size: 48px; margin-bottom: 20px; }
            .hero p { font-size: 18px; color: #cccccc; max-width: 600px; margin: 0 auto 40px auto; }
            .btn { background-color: #00ff41; color: #000; padding: 12px 30px; text-decoration: none; font-weight: bold; border-radius: 4px; text-transform: uppercase; }
            .btn:hover { background-color: #fff; }
            .content { padding: 40px; max-width: 1000px; margin: 0 auto; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
            .card { background-color: #262626; padding: 25px; border-radius: 8px; border-left: 4px solid #444; }
            .card h3 { color: #00ff41; margin-top: 0; }
            footer { text-align: center; padding: 20px; color: #666; font-size: 12px; margin-top: 50px; border-top: 1px solid #333; }
        </style>
    </head>
    <body>
        <header>
            <h1>Hacksmarter<span style="color:#fff">.org</span></h1>
            <nav>
                <a href="#">COURSES</a>
                <a href="#">ENTERPRISE</a>
                <a href="#">LOGIN</a>
            </nav>
        </header>
        
        <div class="hero">
            <h2>Secure the Cloud. Defend the Future.</h2>
            <p>Welcome to the Hacksmarter internal portal. Please log in to access your assigned training environments.</p>
            <a href="#" class="btn">Access Student Portal</a>
        </div>

        <div class="content">
            <div class="card">
                <h3>Latest Updates</h3>
                <p>We have updated our S3 Security Module. Students should now be able to access the new bucket policies lab.</p>
                <small>Posted: Oct 24, 2023</small>
            </div>
            <div class="card">
                <h3>System Status</h3>
                <p>All training nodes are operational. <br><strong>Note to devs:</strong> Please stop storing backup keys in the web root. Use the secure S3 bucket.</p>
            </div>
        </div>

        <footer>
            &copy; 2024 Hacksmarter Security Training. All rights reserved.
        </footer>
    </body>
    </html>
    HTML

    # Set permissions so apache can read it
    chown apache:apache /var/www/html/index.html
    chmod 644 /var/www/html/index.html
  EOF

  tags = {
    Name = "cg-webserver-${var.cgid}"
    Stack = var.stack_name 
    Scenario = var.scenario_name
  }
}

# 4. SECURITY GROUP
resource "aws_security_group" "sg" {
  name        = "cg-sg-${var.cgid}"
  description = "Web Server Security Group"
  vpc_id      = aws_vpc.vpc.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  # HTTPS Access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-sg-${var.cgid}"
  }
}