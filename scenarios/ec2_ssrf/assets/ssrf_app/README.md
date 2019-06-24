# Addendum

This app was adopted from https://github.com/sethsec/Nodejs-SSRF-App.git with love and gratitude.

# Nodejs-SSRF-App
Nodejs application intentionally vulnerable to SSRF

#Operating Systems
Ubuntu 14.04 TLS

Kali 2.0

#Download and Setup

```ShellSession
seth@ubuntu:/opt# sudo git clone https://github.com/sethsec/Nodejs-SSRF-App.git
seth@ubuntu:/opt# cd Nodejs-SSRF-App/
seth@ubuntu:/opt/Nodejs-SSRF-App# sudo ./install.sh

 To start the server:
  sudo nodejs ssrf-demo-app.js
  sudo nodejs ssrf-demo-app.js -p 8080

seth@ubuntu:/opt/Nodejs-SSRF-App# sudo nodejs ssrf-demo-app.js

##################################################
#
#  Server listening for connections on port:80
#  Connect to server using the following url:
#  -- http://[server]:80/?url=[SSRF URL]
#
##################################################

```
