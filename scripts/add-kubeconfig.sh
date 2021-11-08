#!/bin/bash
test -n "$1" && echo CLUSTER is "$1" || "echo CLUSTER1 is not set && exit"
test -n "$2" && echo CLUSTER is "$2" || "echo CLUSTER2 is not set && exit"
CLUSTER1=$(echo $1 | tr -d '[:space:]')
CLUSTER2=$(echo $2 | tr -d '[:space:]')
echo "Setting kubectl config context"
aws eks update-kubeconfig --name $CLUSTER2
aws eks update-kubeconfig --name $CLUSTER1
echo "Setting kubectl config context for both clusters done."