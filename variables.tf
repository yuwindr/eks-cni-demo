variable "project" {
    default = {
        name = "eks-master"
    }
}

variable subnet_az_mapping {
    description = "subnet az mapping"
    type = list 
    default = ["a","b","c"]
}

variable "iam_permissions_boundary_policy_arn" {
    description = "IAM Permissions Boundary Policy ARN to be attached to all IAM roles created"
    type = string
    default = "arn:aws:iam::500605182284:policy/GCCIAccountBoundary"
}

variable "eks_vpc_id" {
    description = "VPC ID where the EKS will be deployed into"
    type = string
}

variable "ec2_vpc_id" {
    description = "VPC ID where the EKS will be deployed into"
    type = string
}

variable "vpc_main_cidr" {
    description = "Main CIDR block of the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "vpc_secondary_cidr" {
    description = "Secondary CIDR block of the VPC"
    type = string
    default = "100.64.0.0/16"
}

variable "eks_cluster_name" {
    description = "Name of the EKS cluster to be created"
    type = string
    default = "eks-cluster-demo"
}

variable "key_pair_name" {
    description = "Key Pair name to be used for EC2 instances"
    type = string
    default = "container-wind-kpair"
}

variable "ec2_ami_id" {
    description = "AMI ID to be used by the target EC2 instance"
    type = string
    default = "ami-07191cf2912e097a6"
}

variable "serviceA_container_image" {
    description = "Container image for Service A (ssh-able container)"
    type = string
    default = "500605182284.dkr.ecr.ap-southeast-1.amazonaws.com/service-a-ssh:latest" 
}

variable "serviceB_container_image" {
    description = "Container image for Service B (returns caller IP address)"
    type = string
    default = "500605182284.dkr.ecr.ap-southeast-1.amazonaws.com/service-b-printreq:latest" 
}