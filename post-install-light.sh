#!/bin/bash

FORGEDOMAIN=${1}

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

# More Aliases configuration
$WORKSPACE_DIR/configuration/alias/template.sh
