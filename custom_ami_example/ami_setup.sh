#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

OS_ID=$(. /etc/os-release && echo $ID)
DEBIAN_OS=("ubuntu" "debian")
RHEL_OS=("rhel" "amzn" "sles" "centos" "rocky" "alma" "fedora")

# Check the distribution's family
if [[ " ${DEBIAN_OS[@]} " =~ " ${OS_ID} " ]]; then
    echo "$OS_ID is Debian-based"
    OS_FAMILY="debian"
elif [[ " ${RHEL_OS[@]} " =~ " ${OS_ID} " ]]; then
    echo "$OS_ID is RHEL-based"
    OS_FAMILY="rhel"
else
    echo "Unsupported OS: $OS_ID"
    exit 1
fi

if [ "$OS_FAMILY" == "debian" ]; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gpg unzip
elif [ "$OS_FAMILY" == "rhel" ]; then
    yum update -y
    yum install -y ca-certificates curl gpg unzip yum-plugin-versionlock --allowerasing
fi

# Install AWS CLI
wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip awscli-exe-linux-x86_64.zip
sh ./aws/install
rm -rf aws awscli-exe-linux-x86_64.zip

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Containerd
CONTAINERD_VERSION="${2:-2.0.2}"
wget https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
rm -rf containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mkdir -p /usr/local/lib/systemd/system
mv containerd.service /usr/local/lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

# configure containerd
CONTAINERD_CONFIG_FILE=/etc/containerd/config.toml
mkdir -p "$(dirname "$CONTAINERD_CONFIG_FILE")"
containerd config default | tee $CONTAINERD_CONFIG_FILE > /dev/null
sed -i 's/^\(\s*SystemdCgroup\)\s*=\s*false$/\1 = true/' $CONTAINERD_CONFIG_FILE
sed -i 's|^\(\s*sandbox_image\)\s*=\s*\(.*\)$|\1 = "registry.k8s.io/pause:3.10"|' $CONTAINERD_CONFIG_FILE

# Install Runc
RUNC_VERSION="v${3:-1.2.4}"
wget https://github.com/opencontainers/runc/releases/download/$RUNC_VERSION/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
rm -rf runc.amd64

# Install CNI plugins
CNI_PLUGINS_VERSION="v${4:-1.6.2}"
wget https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGINS_VERSION/cni-plugins-linux-amd64-$CNI_PLUGINS_VERSION.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-$CNI_PLUGINS_VERSION.tgz
rm -rf cni-plugins-linux-amd64-$CNI_PLUGINS_VERSION.tgz

# restart containerd
systemctl restart containerd

# Forwarding IPv4 and letting iptables see bridged traffic
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe br_netfilter
modprobe overlay

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv6.conf.all.rp_filter = 0
EOF
sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Install kubectl, kubelet and kubeadm
K8S_VERSION="v${1:-1.32}"

if [ "$OS_FAMILY" == "debian" ]; then
    curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | \
      gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | \
      tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install --quiet --yes kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
elif [ "$OS_FAMILY" == "rhel" ]; then
    cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/rpm/repodata/repomd.xml.key
EOF
    yum install -y kubelet kubeadm kubectl
    systemctl enable --now kubelet
    yum versionlock kubelet kubeadm kubectl
fi