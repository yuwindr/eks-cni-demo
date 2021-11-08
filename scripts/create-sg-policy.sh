#!/bin/bash
cn1=$(echo $1 | tr -d '[:space:]')
cn2=$(echo $2 | tr -d '[:space:]')
sg=$(echo $3 | tr -d '[:space:]')

# Create the pod security group policy file
cat << EoF > pod-sg-policy.yaml
apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy
metadata:
  name: allow-all-from-vpc
spec:
  podSelector:
    matchLabels:
      customSG: "true"
  securityGroups:
    groupIds:
      - ${sg}
EoF

echo "created pod-sg-policy.yaml"

# cluster 2
aws eks update-kubeconfig --name $cn2
kubectl set env ds aws-node -n kube-system ENABLE_POD_ENI=true
# Apply the CRD config
echo "apply the pod-sg CRD for $cn1"
kubectl apply -f pod-sg-policy.yaml

# set kubeconfig back to cluster 1
aws eks update-kubeconfig --name $cn1