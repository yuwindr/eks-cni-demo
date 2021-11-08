## DISCLAIMER


Questions:
- Seems like the default pods `aws-node-xxx` and `kube-proxy-xxx` will use the primary CIDR range (10.x). What is the reason for this? in case customers ask
- Not sure how to customise such that only 1 nodegroup will have the AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

## TODO
1. Change the setup to use existing VPCs - OK
1. Kubernetes deployments ([useful tutorial to deploy pods to specific nodes](https://medium.com/kubernetes-tutorials/learn-how-to-assign-pods-to-nodes-in-kubernetes-using-nodeselector-and-affinity-features-e62c437f3cf8)) - OK, pendign docker image
    1. Image A to nodegroup1
    1. Image B to nodegroup1
    1. Image A to nodegroup2
    1. Image B to nodegroup2
1. Use another VPC and deploy an ec2 that returns the caller's IP address - OK, pending docker image userdata
1. Create VPC endpoints - ECR, sts, s3 etc. [link](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html#vpc-endpoints-private-clusters)
1. Create IAM role for EC2
1. chmod script
1. Test IAM role creation using Permissions Boundary

Image list:
- Image A - SSH-able container
- Image B - returns caller IP address

<br>

## Deployment

<br>

### Pre-requisites

1. Create Cloud9 environment with the following inputs
- Environment type: `Create a new EC2 instance for environment (direct access)`
- Instance type: `t2.micro`
- Platform: `Amazon Linux 2`
- Network settings: choose a public subnet in the VPC where EKS cluster will be deployed

1. Cloud9 setup
    - Create IAM Role and attach it to Cloud9 instance
        - Create an IAM Role that can be assumed by EC2 and has `AdministratorAccess` IAM policy and `GCCIAccountPolicy` Permissions Boundary policy attached.
        - In the Cloud9 environment, click `Manage EC2 Instance` which will open up the EC2 console. Attach the created IAM role to the EC2 instance.
        - Return to the Cloud9 environment and click the gear icon (in top right corner). Select `AWS Settings` and turn off `AWS managed temporary credentials`.
        - Run `aws sts get-caller-identity` and ensure that the role being used is the newly created IAM Role.
    - Install tools
        ```bash
            sudo curl --silent --location -o /usr/local/bin/kubectl \
            https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl

            sudo chmod +x /usr/local/bin/kubectl

            kubectl completion bash >>  ~/.bash_completion
            . /etc/profile.d/bash_completion.sh
            . ~/.bash_completion
        ```
    - Clone the Github repository
        ```bash
            git clone __
            # enable scripts to be executed
            chmod +x scripts/*.sh
        ```

1. Tag VPC subnets  
    - For subnets that we want to include in the EKS cluster, tag it with the following keys and appropriate values:
        - Tier: Private/Public
        - CIDR: Main/Secondary
        - *E.g. for public subnet in the main VPC CIDR range (10.0.0.0/16), it should have tags `Tier=Public` and `CIDR=Main`.*
    - For subnet that we want to deploy target EC2 instance, tag it with the following keys and appropriate values:
        - Tier: Private/Public

1. Fill in `terraform.tfvars` with the necessary values

<br>

### Deployment steps

```bash
    terraform init
    # optional
    terraform plan
    terraform apply
```

<br>

## Verification

<br>

### Check cluster details
- There should be 2 kubectl config contexts added - 1 for cluster 1 (CNI enabled) and 1 for cluster 2 (CNI disabled). The activated context is cluster 1. Run the following commands to get basic information:
    ```bash
    # you should see 2 nodes
    kubectl get nodes

    # you should see 4 pods, 2 for service A, 2 for service B
    # for cluster 1, the IP should be using the secondary CIDR, e.g. 100.x.x.x
    # for cluster 2, the IP should be using the main CIDR, e.g. 10.x.x.x
    kubectl get pods -o wide
    ```

<br>

### SSH into Cluster 1 Service A pod
- 

<br>

### Use Busybox image
- Alternatively, we can use Busybox image to create a temporary container in the cluster (similar functionality to Service A)
    ```
    kubectl run -i --rm --tty debug --image=busybox -- sh
    curl nginx -O -
    curl <IP address> -O -
    ```

<br>

## Add IAM role as admin (Optional)

Enable kubectl
`aws eks update-kubeconfig --name <Cluster Name>`

```bash
kubectl describe configmap -n kube-system aws-auth
ROLE_ARN=$(aws iam get-role --role-name <IAM Role Name> --query "Role.Arn" --output text)
eksctl create iamidentitymapping --cluster <Cluster Name> --arn ${ROLE_ARN} --group system:masters --username admin
kubectl describe configmap -n kube-system aws-auth
```

<br>

## Troubleshooting

If terraform apply fails with `Permission denied` error for either `annotate-nodes.sh` or `cni-cycle-nodes.sh`, run the following commands:
`chmod +x annotate-nodes.sh`
`chmod +x enable-cni.sh`

<br>

## Deploy an application (nginx)

```
kubectl create deployment nginx --image=nginx
kubectl scale --replicas=3 deployments/nginx
kubectl expose deployment/nginx --type=NodePort --port 80
kubectl get pods -o wide
```

<br>

## References
- Starting Terraform files + Terraform modules from ftseng@
- Scripts to enable CNI and annotate nodes taken from [here](https://tf-eks-workshop.workshop.aws/500_eks-terraform-workshop/570_advanced-networking.html)