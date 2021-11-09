terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }

  }

  backend "s3" {
    bucket  = "<bucket-name>"
    key     = "terraform.tfstate"
    region  = "ap-southeast-1"
  }

  required_version = ">= 0.15.1"
}

provider "aws" {
  region  = "ap-southeast-1"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster_1.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster_1.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.eks_cluster_1.name
    ]
  }
  alias = "cluster_1"
}