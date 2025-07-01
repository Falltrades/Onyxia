#!/bin/bash

FORGEDOMAIN=${1}
OS_PASSWORD=${2}
AGE_SECRET_KEY=${3}
VAULT=${4}

# Git setup
cat <<EOF > $HOME/.git-credentials
https://${GIT_USER_NAME}:${GIT_PERSONAL_ACCESS_TOKEN}@gitlab.${FORGEDOMAIN}
EOF

cat <<EOF > $HOME/.gitconfig
[user]
    name = ${GIT_USER_NAME}
    email = ${GIT_USER_MAIL}
[credential]
        helper = store
[core]
        editor = vim
EOF

# Openstack setup
cat <<EOF > $HOME/.credentials
export OS_PASSWORD='${OS_PASSWORD}'
EOF

cat <<EOF >> $HOME/.bashrc
if [ -f ~/.credentials ]; then
    . ~/.credentials
fi
EOF

# More Aliases configuration
$WORKSPACE_DIR/configuration/alias/template.sh

# SOPS decryption
mkdir -p $HOME/keys/
echo ${AGE_SECRET_KEY} > $HOME/keys/Onyxia.txt
cd $WORKSPACE_DIR/configuration/kubeconfig/encrypted/
$WORKSPACE_DIR/configuration/sops/decrypt.sh

# VAULT decryption
mkdir -p $HOME/.ssh/
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault
echo "$VAULT" > ${ANSIBLE_VAULT_PASSWORD_FILE}
for PRIVATE_KEY in `ls $WORKSPACE_DIR/configuration/ssh_keys/private`; do
    ansible-vault decrypt $WORKSPACE_DIR/configuration/ssh_keys/private/${PRIVATE_KEY} --output $HOME/.ssh/${PRIVATE_KEY}
done
