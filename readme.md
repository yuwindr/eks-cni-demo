# EKS CNI Custom Networking Demo


## Disclaimer

> **This project is used for demo purposes only and should NOT be considered for production use.**

<br>

## Deployment

<br>

### Pre-requisites

1. Create Cloud9 environment with the following inputs
    - Environment type: `Create a new EC2 instance for environment (direct access)`
    - Instance type: `t2.micro`
    - Platform: `Amazon Linux 2`
    - Network settings: choose a public subnet in the primary CIDR range of the VPC where EKS cluster will be deployed

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

            sudo yum -y install jq gettext bash-completion moreutils

            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
        ```
    - Clone the Github repository
        ```bash
            git clone https://github.com/yuwindr/eks-cni-demo.git
            # enable scripts to be executed
            cd eks-cni-demo/
            chmod +x scripts/*.sh
        ```

1. Tag VPC subnets  
    - For subnets that we want to include in the EKS cluster, tag it with the following keys and appropriate values:
        - Tier: Private/Public
        - CIDR: Main/Secondary
        - *E.g. for public subnet in the main VPC CIDR range (10.0.0.0/16), it should have tags `Tier=Public` and `CIDR=Main`.*
        - *Note: this template expects 1 public and 1 private subnet in each of the two AZs: ap-southeast-1a and ap-southeast-1b*
    - For subnet that we want to deploy target EC2 instance, tag it with the following keys and appropriate values:
        - Tier: Private/Public
        - *Note: this template expects 1 public subnet in ap-southeast-1a AZ*

1. Terraform setup
    - Create an S3 bucket to store Terraform state files
    - Create an EC2 Key Pair. This will be used to SSH into the EC2 instances during Verification step later.
    - Open main.tf and replace the `<bucket-name>` under `backend "s3"` with the bucket name created above. The Terraform state files will be stored there.
    - Fill in `terraform.tfvars` with the necessary values

<br>

### Terraform deployment

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
- There will be 2 kubectl config contexts added - 1 for cluster 1 (CNI enabled) and 1 for cluster 2 (CNI disabled). The activated context is cluster 1. Run the following commands to get basic information:
    ```bash
    # you should see 2 nodes
    kubectl get nodes
    # you should see 4 pods, 2 for service A, 2 for service B
    # for cluster 1, the IP should be using the secondary CIDR, e.g. 100.x.x.x
    kubectl get pods -o wide
    # Take note of one of the Service A pods' IP address and one of the Service B pods' IP address

    # switch context to cluster 2
    ## copy the context name for cluster 2
    kubectl config get-contexts
    kubectl config use-context <cluster 2 context name>
    # for cluster 2, the IP should be using the main CIDR, e.g. 10.x.x.x
    kubectl get pods -o wide
    # Take note of one of the Service B pods' IP address
    ```

<br>

### SSH into Cluster 1 Service A pod and verify network configuration

    ```bash
        # SSH into Service A, use demoPW839x as password
        ssh userdemo@<IP address of Cluster 1 Service A, should be 100.x IP>
        
        # Scenario 1 - Make an HTTP Call to ifconfig.me - should return a public IP
        curl ifconfig.me

        # Scenario 2 - Make an HTTP Call to target EC2 - should return a 10.x IP
        ## private IP address is printed in Terraform outputs
        curl <private IP address of EC2 instance>

        # Scenario 3 - Make an HTTP Call to Cluster 1 Service B - should return a 100.x IP
        curl <Cluster 1 Service B IP address, should be 100.x IP>

        # Scenario 4 - Make an HTTP Call to Cluster 2 Service B - should return a 100.x IP
        curl <Cluster 1 Service B IP address, should be 10.x IP>
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

## References
- Starting Terraform files + Terraform modules from @ftseng
- Scripts to enable CNI and annotate nodes taken from [here](https://tf-eks-workshop.workshop.aws/500_eks-terraform-workshop/570_advanced-networking.html)