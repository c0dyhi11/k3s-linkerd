#!/bin/bash
cd ~

CLUSTER_CIDR='${pod_cidr}'
SERVICE_CIDR='${service_cidr}'
K3S_VER='${k3s_version}'
CLUSTER_NAME='${cluster_name}'
MASTER_NODE_IP='${master_node_ip}'
WORKER_NODE_IP='${worker_node_ip}'
SSH_PRIVATE_KEY='${ssh_private_key}'
DOMAIN='${domain}'

echo "write Private Key to file"
cat <<EOF >/root/.ssh/id_rsa
$SSH_PRIVATE_KEY
EOF
chmod 0400 /root/.ssh/id_rsa

echo "Set SSH config to not do StrictHostKeyChecking"
cat <<EOF >/root/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
chmod 0400 /root/.ssh/config

echo "Install k3s without Traefik"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VER INSTALL_K3S_EXEC="server --no-deploy traefik --disable-cloud-controller --kubelet-arg cloud-provider=external --cluster-cidr $CLUSTER_CIDR --service-cidr $SERVICE_CIDR --cluster-domain $CLUSTER_NAME.$DOMAIN" sh -

echo "Wait for k3s token to exist"
until [ -f /var/lib/rancher/k3s/server/node-token ]; do sleep 1; done
echo "Wait until the kubeconfig is generated"
until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 1; done

echo "Gather token and install k3s on worker node via SSH"
TOKEN=`cat /var/lib/rancher/k3s/server/node-token`
URL="https://$MASTER_NODE_IP:6443"
ssh root@$WORKER_NODE_IP <<-SSH
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$k3s_ver K3S_URL=$URL K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="agent --kubelet-arg cloud-provider=external" sh -
SSH
