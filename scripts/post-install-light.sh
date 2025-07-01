#!/bin/bash

# Git setup
cat <<EOF > $HOME/.gitconfig
[user]
    name = ${GITHUB_USERNAME}
    email = ${GITHUB_USERMAIL}
[core]
        editor = vim
EOF

# More Aliases configuration
$WORKSPACE_DIR/onyxia/alias/template.sh

# Install self-signed certficate
echo -e $TP_BASTION_SSL_CERT > /usr/local/share/ca-certificates/tp_bastion.pem
echo -e $TP_CPIN_SSL_CERT > /usr/local/share/ca-certificates/tp_cpin.pem
echo -e $TP_CPIN_SSL_CERT2 > /usr/local/share/ca-certificates/tp_cpin_sdan.pem

sudo update-ca-certificates
