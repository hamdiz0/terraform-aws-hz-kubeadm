#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

K8S_API=$1
USERNAME=$2

# Initialize k8s
echo "Satrting the cluster ..."
kubeadm config images pull
kubeadm init  --ignore-preflight-errors=all \
              --control-plane-endpoint=$K8S_API:6443 \
              --upload-certs

# allow root user to manage the cluster
mkdir -p /root/.kube
cp -v /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'source <(kubectl completion bash)' >> /etc/bash.bashrc

# allow user (admin:default for debian) to manage the cluster
mkdir -p /home/$USERNAME/.kube
cp -v /etc/kubernetes/admin.conf /home/$USERNAME/.kube/config
chown -R $USERNAME:$USERNAME /home/$USERNAME/.kube
chmod 600 /home/$USERNAME/.kube/config
echo "export KUBECONFIG=/home/$USERNAME/.kube/config" | tee -a /home/$USERNAME/.bashrc > /dev/null

# install network plugin (weave)
WEAVE_VERSION="1.32"
kubectl apply -f https://reweave.azurewebsites.net/k8s/v$WEAVE_VERSION/net.yaml


JOIN_COMMAND=$(kubeadm token create --print-join-command)
CERTIFICATE=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)

# generate worker join script
echo $JOIN_COMMAND > "/home/$USERNAME/worker_join_script.sh"

# generate master join script
cat << EOF > "/home/$USERNAME/master_join_script.sh"
# join command for adding additional masters
kubeadm config images pull
$JOIN_COMMAND --certificate-key $CERTIFICATE --control-plane --ignore-preflight-errors=all

# allow root user to manage the cluster
mkdir -p /root/.kube
cp -iv /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'source <(kubectl completion bash)' >> /etc/bash.bashrc

mkdir -p /home/$USERNAME/.kube
cp -i /etc/kubernetes/admin.conf /home/$USERNAME/.kube/config
chown -R $USERNAME:$USERNAME /home/$USERNAME/.kube
chmod 600 /home/$USERNAME/.kube/config
echo "export KUBECONFIG=/home/$USERNAME/.kube/config" | tee -a /home/$USERNAME/.bashrc > /dev/null
EOF