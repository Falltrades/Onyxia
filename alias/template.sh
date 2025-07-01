#!/bin/bash

cat <<EOF >> $HOME/.bash_aliases
alias ns='$WORKSPACE_DIR/onyxia/scripts/namespace.sh'
alias tp='source $WORKSPACE_DIR/onyxia/scripts/teleport_login.sh'
alias ktp='$WORKSPACE_DIR/onyxia/scripts/kill_tsh_process.sh'
alias glc='$WORKSPACE_DIR/onyxia/scripts/github_local_config.sh'
EOF
