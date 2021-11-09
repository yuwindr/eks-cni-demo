#!/bin/bash
test -n "$1" && echo CLUSTER is "$1" || "echo CLUSTER1 is not set && exit"
CLUSTER1=$(echo $1 | tr -d '[:space:]')
cidr=$(echo $2 | tr -d '[:space:]')
echo "Setting kubectl config context"
aws eks update-kubeconfig --name $CLUSTER1
echo "Setting kubectl config context done."
echo "Adding rules to control plane security group."
sg1=$(aws eks describe-cluster --name $CLUSTER1 --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $sg1 --protocol all --port -1 --cidr $cidr
echo "Adding rules to control plane security group."