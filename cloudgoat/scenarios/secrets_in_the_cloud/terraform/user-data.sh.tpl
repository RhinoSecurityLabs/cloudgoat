#!/bin/bash

# This is a terraform template file.

# It is used to generate the user-data.sh file that is used to configure the EC2
# instance.


yum update -y
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum install -y httpd mariadb-server
systemctl start httpd
systemctl enable httpd
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# Install PHP app
echo "<?php
define('DB_SERVER', '${db_host}');
define('DB_USERNAME', '${db_username}');
define('DB_PASSWORD', '${db_password}');
define('DB_NAME', '${db_name}');
\$link = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);
if(\$link === false){
    die('ERROR: Could not connect. ' . mysqli_connect_error());
}
?>" > /var/www/html/db.php

# Update webapp URL
echo "WebApp URL: ${webapp_url}" > /var/www/html/index.html
