#!/bin/bash

echo "[*] Installing Node and NPM"
apt-get update 
apt-get -y install nodejs npm
echo "[*] Installing node packages"
npm install http express needle command-line-args
echo 
echo "[*] Install complete!"
echo
echo " To start the server:"
echo "  sudo nodejs ssrf-demo-app.js"
echo "  sudo nodejs ssrf-demo-app.js -p 8080"
echo 
