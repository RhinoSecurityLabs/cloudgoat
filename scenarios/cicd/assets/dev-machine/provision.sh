#!/bin/bash
mkdir -p /home/ssm-user/.ssh
cat > /home/ssm-user/.ssh/id_rsa <<EOF
${private_ssh_key}
EOF