#!/bin/bash
test -n "$1" && echo CLUSTER is "$1" || "echo CLUSTER is not set && exit"
CLUSTER=$(echo $1 | tr -d '[:space:]')
# echo "Setting kubectl config context"
aws eks update-kubeconfig --name $CLUSTER
# set custom networking for the CNI
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
# quick look to see if it's now set
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment | grep CUSTOM
