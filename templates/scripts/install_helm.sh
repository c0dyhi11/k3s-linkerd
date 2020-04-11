#!/bin/bash
HELM_VER='${helm_version}'

cd /root/bootstrap/
echo "Install helm"
curl -LO https://get.helm.sh/helm-$HELM_VER-linux-amd64.tar.gz
tar -xf helm-$HELM_VER-linux-amd64.tar.gz 
mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64 helm-$HELM_VER-linux-amd64.tar.gz

echo "Copy the kube config to the 'Known' location for things like helm"
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

echo "Add the stable repo to helm"
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
