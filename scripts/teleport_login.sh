#!/bin/bash

export TELEPORT_TLS_ROUTING_CONN_UPGRADE=true

INTERNAL_TELEPORT=${INTERNAL_TELEPORT}
PUBLIC_TELEPORT=${PUBLIC_TELEPORT}
PUBLIC_TELEPORT2=${PUBLIC_TELEPORT2}

# Define available TP_PROXY options
declare -A PROXIES
PROXIES["1"]=${INTERNAL_TELEPORT}
PROXIES["2"]=${PUBLIC_TELEPORT}
PROXIES["3"]=${PUBLIC_TELEPORT2}

# Define clusters per proxy
declare -A CLUSTERS_BASTION
CLUSTERS_BASTION["1"]="dso-prod 50000"
CLUSTERS_BASTION["2"]="prod-dso-r2 50001"
CLUSTERS_BASTION["3"]="dso-integ 50002"

declare -A CLUSTERS_TELEPORT
CLUSTERS_TELEPORT["1"]="sdid 40000"
CLUSTERS_TELEPORT["2"]="sdid-hp 40001"
CLUSTERS_TELEPORT["3"]="external 40002"
CLUSTERS_TELEPORT["4"]="formation 40003"

declare -A CLUSTERS_TELEPORT2
CLUSTERS_TELEPORT2["1"]="cpin-console 40000"
CLUSTERS_TELEPORT2["2"]="cpin-console-hp 40001"
CLUSTERS_TELEPORT2["3"]="cpin-app 40002"
CLUSTERS_TELEPORT2["4"]="cpin-app-hp 40003"

# Check if TP_USER is set, else prompt for it
if [[ -z "$TP_USER" ]]; then
    read -p "Enter your Teleport username (TP_USER): " TP_USER
    export TP_USER
else
    echo "Using existing TP_USER: $TP_USER"
fi

# Ask user for proxy selection
echo "Select a TP_PROXY:"
for key in "${!PROXIES[@]}"; do
    echo "$key) ${PROXIES[$key]}"
done

read -p "Enter choice [1-3]: " proxy_choice
TP_PROXY=${PROXIES[$proxy_choice]}

case "$TP_PROXY" in
  "$INTERNAL_TELEPORT")
    GITOPS_REPO_BASE_PATH=${INTERNAL_GITOPS_REPO_BASE_PATH}
    ;;
  "$PUBLIC_TELEPORT")
    GITOPS_REPO_BASE_PATH=${PUBLIC_GITOPS_REPO_BASE_PATH}
    ;;
  "$PUBLIC_TELEPORT2")
    GITOPS_REPO_BASE_PATH=${PUBLIC_GITOPS_REPO_BASE_PATH}
    ;;
esac

# Ask user for cluster selection based on chosen proxy
if [[ "$TP_PROXY" == "${PROXIES[1]}" ]]; then
    echo "Select a TP_CLUSTER for ${PROXIES[1]}:"
    #unset SSL_CERT_FILE
    export SSL_CERT_FILE=/usr/local/share/ca-certificates/tp_bastion.pem
    for key in "${!CLUSTERS_BASTION[@]}"; do
        echo "$key) ${CLUSTERS_BASTION[$key]}"
    done
    read -p "Enter choice [1-4]: " cluster_choice
    CLUSTER_INFO=(${CLUSTERS_BASTION[$cluster_choice]})
elif [[ "$TP_PROXY" == "${PROXIES[2]}" ]]; then
    echo "Select a TP_CLUSTER for ${PROXIES[2]}:"
    export SSL_CERT_FILE=/usr/local/share/ca-certificates/tp_cpin.pem
    for key in "${!CLUSTERS_TELEPORT[@]}"; do
        echo "$key) ${CLUSTERS_TELEPORT[$key]}"
    done
    read -p "Enter choice [1-4]: " cluster_choice
    CLUSTER_INFO=(${CLUSTERS_TELEPORT[$cluster_choice]})
else
    echo "Select a TP_CLUSTER for ${PROXIES[3]}:"
    export SSL_CERT_FILE=/usr/local/share/ca-certificates/tp_cpin2.pem
    for key in "${!CLUSTERS_TELEPORT2[@]}"; do
        echo "$key) ${CLUSTERS_TELEPORT2[$key]}"
    done
    read -p "Enter choice [1-4]: " cluster_choice
    CLUSTER_INFO=(${CLUSTERS_TELEPORT2[$cluster_choice]})
fi

TP_CLUSTER_NAME=${CLUSTER_INFO[0]}
TP_CLUSTER_PORT=${CLUSTER_INFO[1]}

# Export variables
export TP_PROXY
export TP_CLUSTER=("${TP_CLUSTER_NAME}" "${TP_CLUSTER_PORT}")

# Login and setup commands
echo "Logging into Teleport as user ${TP_USER}..."
eval $(tsh env --unset)
tsh login --proxy="${TP_PROXY}:443" --auth=local --user="${TP_USER}" "${TP_PROXY}"

echo "Logging into Kubernetes cluster ${TP_CLUSTER_NAME}..."
tsh kube login "${TP_CLUSTER_NAME}"

# Check if port is already in use using ss
if ss -tuln | grep -q ":${TP_CLUSTER_PORT} "; then
    echo "⚠️  Port ${TP_CLUSTER_PORT} is already in use. Skipping 'tsh proxy kube' command."
else
    echo "Starting Teleport kube proxy on port ${TP_CLUSTER_PORT}..."
    tsh proxy kube --port "${TP_CLUSTER_PORT}" &
    sleep 2  # Give the proxy time to start
fi

# Wait briefly to ensure proxy starts before setting KUBECONFIG
sleep 2

export KUBECONFIG="${HOME}/.tsh/keys/${TP_PROXY}/${TP_USER}-kube/${TP_PROXY}/localproxy-${TP_CLUSTER_PORT}-kubeconfig"
export K8S_AUTH_KUBECONFIG="${KUBECONFIG}"
export K8S_AUTH_PROXY="http://127.0.0.1:${TP_CLUSTER_PORT}"
export GITOPS_REPO_PATH=$WORKSPACE_DIR/$GITOPS_REPO_BASE_PATH-${TP_CLUSTER_NAME}

echo "Environment configured:"
echo "  TP_USER: $TP_USER"
echo "  TP_PROXY: $TP_PROXY"
echo "  TP_CLUSTER: ${TP_CLUSTER_NAME} (${TP_CLUSTER_PORT})"
echo "  KUBECONFIG: $KUBECONFIG"
echo "  K8S_AUTH_PROXY: $K8S_AUTH_PROXY"
echo "  GITOPS_REPO_PATH: $GITOPS_REPO_PATH"

# Set KUBECONFIG_INFRA to null
export KUBECONFIG_INFRA=null
export KUBECONFIG_PROXY_INFRA=null
echo "Additional infra config exported:"
echo "  KUBECONFIG_INFRA: $KUBECONFIG_INFRA"
echo "  KUBECONFIG_PROXY_INFRA: $KUBECONFIG_PROXY_INFRA"
