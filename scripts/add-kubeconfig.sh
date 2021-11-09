#!/bin/bash
test -n "$1" && echo CLUSTER is "$1" || "echo CLUSTER1 is not set && exit"
test -n "$2" && echo CLUSTER is "$2" || "echo CLUSTER2 is not set && exit"
CLUSTER1=$(echo $1 | tr -d '[:space:]')
CLUSTER2=$(echo $2 | tr -d '[:space:]')
cidr=$(echo $3 | tr -d '[:space:]')
echo "Setting kubectl config context"
aws eks update-kubeconfig --name $CLUSTER2
aws eks update-kubeconfig --name $CLUSTER1
echo "Setting kubectl config context for both clusters done."
echo "Adding rules to control plane security groups for both clusters."
sg1=$(aws eks describe-cluster --name $CLUSTER1 --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $sg --protocol all --port -1 --cidr $cidr
sg2=$(aws eks describe-cluster --name $CLUSTER2 --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $sg --protocol all --port -1 --cidr $cidr
echo "Adding rules to control plane security groups done."