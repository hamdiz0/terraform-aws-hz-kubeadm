#!/bin/bash

WORKER_NUMBER=$1
MASTER_NUMBER=$2
CLUSTER_NAME=kubernetes

set -euo pipefail

# wait for nodes to join the cluster
while true; do
    if [ $(kubectl get nodes | wc -l) -eq $((WORKER_NUMBER + MASTER_NUMBER + 1)) ] && ! kubectl get nodes | grep -q "NotReady"; then
        kubectl get nodes
        echo " nodes joined and ready !!!"
        break 
    else
        kubectl get nodes
        echo "waiting for nodes ..."
        sleep 10 
    fi
done

# install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

### Cloud Integration ###
# isntall the aws cloud controller manager
helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update
helm install aws-cloud-controller-manager \
  --namespace kube-system \
  aws-cloud-controller-manager/aws-cloud-controller-manager \
  --set image.tag=v1.30.8 \
  --set args="{ \
          --cloud-provider=aws, \
          --cluster-name=$CLUSTER_NAME, \
          --enable-leader-migration=true, \
          --controllers=*\,-node-route-controller, \
          --cluster-cidr=10.32.0.0/12 \
        }"

### Ingress ###
# install nginx ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.externalTrafficPolicy=Local