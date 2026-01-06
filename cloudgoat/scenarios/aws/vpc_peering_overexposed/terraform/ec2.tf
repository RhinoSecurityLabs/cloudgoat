## EC2 Configuration for vpc_peering_overexposed scenario

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Generate a new SSH key pair for the EC2 instance
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to a file
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/cloudgoat.pem"
  file_permission = "0400"
}

# Register the public key
resource "aws_key_pair" "dev_key_pair" {
  key_name   = "dev-key-${var.cgid}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Dev EC2 instance with IMDSv1 enabled and no hop limit restrictions
resource "aws_instance" "dev_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ec2_instance_type
  iam_instance_profile        = aws_iam_instance_profile.dev_ec2_profile.name
  subnet_id                   = aws_subnet.dev_subnet.id
  vpc_security_group_ids      = [aws_security_group.dev_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.dev_key_pair.key_name

  # Ensure IMDSv1 is enabled (vulnerable configuration)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # IMDSv1 enabled (no token required)
    http_put_response_hop_limit = 1          # Default hop limit
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "==== Installing required packages ===="
              yum update -y
              yum install -y mysql jq aws-cli
              
              echo "==== Installing Session Manager Plugin ===="
              curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
              yum install -y ./session-manager-plugin.rpm
              # Make sure the plugin is in the path for all users
              echo "export PATH=\$PATH:/usr/local/bin:/usr/bin" >> /etc/profile
              # Verify plugin installation
              session-manager-plugin --version
              
              # Enable SSM agent
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF

  tags = {
    Name        = "dev-ec2-${var.cgid}"
    Environment = "Development"
  }
}

# Prod EC2 instance for lateral movement
resource "aws_instance" "prod_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.prod_ec2_profile.name
  subnet_id              = aws_subnet.prod_subnet.id
  vpc_security_group_ids = [aws_security_group.prod_sg.id]

  # Use IMDSv2 for better security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced (token required)
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install required packages before AMI initialization finishes
              # This happens while still connected to Amazon repos
              yum update -y
              yum install -y mysql aws-cli jq httpd php
              
              # Verify MySQL client installation
              if command -v mysql &> /dev/null; then
                echo "MySQL client installed successfully" > /tmp/mysql_install_success
              else
                echo "MySQL client installation failed" > /tmp/mysql_install_failure
              fi
              
              # Set up web server directories
              mkdir -p /var/www/html
              mkdir -p /var/www/config
              
              # Create database environment file in web config directory
              cat > /var/www/config/.env <<'ENVCONFIG'
              # Database Configuration - CONFIDENTIAL
              DB_HOST=${aws_db_instance.customer_db.address}
              DB_PORT=3306
              DB_NAME=${var.db_name}
              DB_USER=${var.db_username}
              DB_PASSWORD=${var.db_password}
              ENVCONFIG
              
              # Set insecure permissions 
              chmod 644 /var/www/config/.env
              chown apache:apache /var/www/config/.env
              
              # Create a sample PHP file that uses the credentials
              cat > /var/www/html/index.php <<'PHPFILE'
              <?php
              // Load environment variables
              $env = parse_ini_file('/var/www/config/.env');
              
              echo "<h1>TELCO Customer Portal</h1>";
              echo "<p>Welcome to the internal customer database portal.</p>";
              echo "<p>System Status: Connected to database at " . getenv('DB_HOST') . "</p>";
              ?>
              PHPFILE
              
              # Start and enable the web server
              systemctl start httpd
              systemctl enable httpd
              
              # Create database script
              cat > /home/ec2-user/init_db.sh <<'INITDB'
              #!/bin/bash
              
              # Source the database configuration
              source /var/www/config/.env
              
              # Wait for RDS to be fully available (can take several minutes after the instance starts)
              MAX_ATTEMPTS=30
              COUNTER=0
              
              echo "Waiting for database connection to be available..."
              while ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "SELECT 1" >/dev/null 2>&1; do
                if [ $COUNTER -ge $MAX_ATTEMPTS ]; then
                  echo "Failed to connect to database after $MAX_ATTEMPTS attempts"
                  exit 1
                fi
                echo "Waiting for database connection (attempt $COUNTER)..."
                sleep 10
                COUNTER=$((COUNTER+1))
              done
              
              echo "Database connection established!"
              
              # Create SQL script
              cat > /tmp/init_customer_db.sql <<'SQL'
              USE customerdb;
              
              CREATE TABLE IF NOT EXISTS customers (
                id INT AUTO_INCREMENT PRIMARY KEY,
                full_name VARCHAR(100) NOT NULL,
                address VARCHAR(255) NOT NULL,
                phone_number VARCHAR(20) NOT NULL,
                ssn VARCHAR(11) NOT NULL,
                drivers_license VARCHAR(20) NOT NULL,
                imei VARCHAR(20) NOT NULL,
                iccid VARCHAR(20) NOT NULL,
                account_number VARCHAR(20) NOT NULL,
                account_pin VARCHAR(6) NOT NULL,
                creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
              );
              
              -- Check if table is empty before inserting
              SET @count = (SELECT COUNT(*) FROM customers);
              
              -- Only insert if table is empty
              SET @sql = IF(@count = 0,
              "INSERT INTO customers (full_name, address, phone_number, ssn, drivers_license, imei, iccid, account_number, account_pin)
              VALUES 
                ('John Smith', '123 Main St, New York, NY 10001', '555-123-4567', '123-45-6789', 'NY12345678', '123456789012345', '310150123456789', 'ACCT001', '1234'),
                ('Jane Doe', '456 Park Ave, Los Angeles, CA 90001', '555-987-6543', '987-65-4321', 'CA98765432', '987654321098765', '310150987654321', 'ACCT002', '5678'),
                ('Robert Johnson', '789 Broadway, Chicago, IL 60601', '555-456-7890', '456-78-9012', 'IL45678901', '456789012345678', '310150456789012', 'ACCT003', '9012'),
                ('Sarah Williams', '321 Oak St, Houston, TX 77001', '555-789-0123', '789-01-2345', 'TX78901234', '789012345678901', '310150789012345', 'ACCT004', '3456'),
                ('Michael Brown', '654 Pine St, Philadelphia, PA 19019', '555-234-5678', '234-56-7890', 'PA23456789', '234567890123456', '310150234567890', 'ACCT005', '7890'),
                ('Jennifer Davis', '987 Maple Dr, Phoenix, AZ 85001', '555-876-5432', '876-54-3210', 'AZ87654321', '876543210987654', '310150876543210', 'ACCT006', '4321'),
                ('David Miller', '147 Walnut Rd, San Diego, CA 92101', '555-258-3690', '258-36-9014', 'CA25836901', '258369014725836', '310150258369014', 'ACCT007', '6543'),
                ('Lisa Wilson', '369 Cherry Ln, Miami, FL 33101', '555-147-2583', '147-25-8369', 'FL14725836', '147258369014725', '310150147258369', 'ACCT008', '8765'),
                ('James Taylor', '258 Birch Blvd, Dallas, TX 75201', '555-369-1470', '369-14-7025', 'TX36914702', '369147025836914', '310150369147025', 'ACCT009', '0987'),
                ('Patricia Anderson', '741 Elm Ct, Seattle, WA 98101', '555-852-9630', '852-96-3014', 'WA85296301', '852963014852963', '310150852963014', 'ACCT010', '2109')",
              "SELECT 'Database already populated, skipping inserts' AS message");
              
              PREPARE stmt FROM @sql;
              EXECUTE stmt;
              DEALLOCATE PREPARE stmt;
              
              -- Verify table was created and populated
              SELECT COUNT(*) AS customer_count FROM customers;
              SQL
              
              # Execute the SQL script
              echo "Initializing database schema and sample data..."
              mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD < /tmp/init_customer_db.sql
              
              # Verify it was successful
              if mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "USE customerdb; SELECT COUNT(*) FROM customers;" | grep -q "10"; then
                echo "Database initialization successful! 10 customer records created."
                
                # Clean up script and evidence
                echo "Cleaning up initialization artifacts..."
                rm -f /tmp/init_customer_db.sql
                
                # Remove cron job
                crontab -l | grep -v "init_db.sh" | crontab -
                
                # Create a marker file to prevent future initialization attempts
                touch /home/ec2-user/.db_initialized
                
                # Clean up log file to remove evidence
                [ -f /home/ec2-user/db_init.log ] && rm -f /home/ec2-user/db_init.log
                
                # This script will self-destruct
                rm -f "$0"
                exit 0
              else
                echo "Database initialization may have failed. Check the database content manually."
                exit 1
              fi
              INITDB
              
              # Make the script executable
              chmod +x /home/ec2-user/init_db.sh
              chown ec2-user:ec2-user /home/ec2-user/init_db.sh
              
              # Run the script immediately and also set it to run on startup
              /home/ec2-user/init_db.sh > /home/ec2-user/db_init.log 2>&1 &
              
              # Add cron entry to try periodically until successful
              echo "*/5 * * * * ec2-user [ ! -f /home/ec2-user/.db_initialized ] && /home/ec2-user/init_db.sh >> /home/ec2-user/db_init.log 2>&1 || (crontab -l | grep -v init_db.sh | crontab -)" | crontab -u ec2-user -

              # Enable SSM agent for lateral movement
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF

  tags = {
    Name        = "prod-ec2-${var.cgid}"
    Environment = "Production"
  }
}

# Copy the private key to the scenario instance directory for easy access
resource "null_resource" "copy_ssh_key" {
  provisioner "local-exec" {
    command = "cp ${path.module}/cloudgoat.pem ../"
  }

  depends_on = [local_file.private_key]
} 