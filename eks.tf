resource "aws_iam_role" "eks_cluster_iam_role" {
  name = "eks-cluster-iam-role"
  assume_role_policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
  permissions_boundary = var.iam_permissions_boundary_policy_arn
}

resource "aws_iam_role" "eks_node_group_iam_role" {
  name = "eks-node-group-iam-role"
  assume_role_policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  permissions_boundary = var.iam_permissions_boundary_policy_arn
}

resource "aws_eks_cluster" "eks_cluster_1" {
  name     = "${var.eks_cluster_name}_1"
  role_arn = aws_iam_role.eks_cluster_iam_role.arn
  vpc_config {
    subnet_ids              = concat(tolist(data.aws_subnet_ids.main_public_subnets.ids))
    endpoint_private_access = true
    endpoint_public_access  = true
  }
  enabled_cluster_log_types = ["api", "audit"]
}

resource "aws_eks_node_group" "cluster_1_node_group1" {
  cluster_name    = aws_eks_cluster.eks_cluster_1.name
  node_group_name = "cluster_1_node_group1"
  node_role_arn   = aws_iam_role.eks_node_group_iam_role.arn
  subnet_ids      = data.aws_subnet_ids.main_public_subnets.ids
  instance_types  = ["m5.large"]
  scaling_config {
    desired_size = 4
    max_size     = 4
    min_size     = 4
  }

  remote_access {
    ec2_ssh_key = var.key_pair_name
  }

  tags = {
    "eks/cluster-name"                            = aws_eks_cluster.eks_cluster_1.name
    "eks/nodegroup-name"                          = format("ng1-%s", aws_eks_cluster.eks_cluster_1.name)
    "eks/nodegroup-type"                          = "managed"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = aws_eks_cluster.eks_cluster_1.name
  }

  depends_on = [
    null_resource.cluster_1_enable_cni
  ]

}

resource "null_resource" "add_kubeconfig" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    aws_eks_cluster.eks_cluster_1
  ]

  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        cn1=$(echo ${aws_eks_cluster.eks_cluster_1.name} | tr -d '[:space:]')
        cidr=$(echo ${var.eks_vpc_main_cidr} | tr -d '[:space:]')
        echo -e "\x1B[35mAdding Kubeconfig......\x1B[0m"
        ./scripts/add-kubeconfig.sh $cn1 $cidr
     EOT
  }
}

resource "null_resource" "cluster_1_enable_cni" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    aws_eks_cluster.eks_cluster_1,
    null_resource.add_kubeconfig
  ]

  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        cn=$(echo ${aws_eks_cluster.eks_cluster_1.name} | tr -d '[:space:]')
        echo -e "\x1B[35mEnabling CNI config......\x1B[0m"
        ./scripts/enable-cni.sh $cn
     EOT
  }
}

# annotate nodes from nodegroup1 only
resource "null_resource" "annotate_nodes" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    aws_eks_node_group.cluster_1_node_group1,
    null_resource.cluster_1_enable_cni
  ]

  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        az1=$(echo ${aws_subnet.secondary_public_subnet_1a.availability_zone} | tr -d '[:space:]')
        az2=$(echo ${aws_subnet.secondary_public_subnet_1b.availability_zone} | tr -d '[:space:]')
        sub1=$(echo ${aws_subnet.secondary_public_subnet_1a.id} | tr -d '[:space:]')
        sub2=$(echo ${aws_subnet.secondary_public_subnet_1b.id} | tr -d '[:space:]')
        cn=$(echo ${aws_eks_cluster.eks_cluster_1.name} | tr -d '[:space:]')
        ng=$(echo ${aws_eks_node_group.cluster_1_node_group1.node_group_name} | tr -d '[:space:]')
        customsg=$(echo ${aws_security_group.eks_pod_sg.id} | tr -d '[:space:]')
        echo -e "\x1B[33mAnnotate nodes ......\x1B[0m"
        ./scripts/annotate-nodes.sh $az1 $az2 $sub1 $sub2 $cn $ng $customsg
        echo -e "\x1B[32mShould see coredns on 100.64.x.y addresses now\x1B[0m"
     EOT
  }
}


output "eks_outputs" {
  value = {
    cluster1 = {
      cluster_name       = aws_eks_cluster.eks_cluster_1.name
      cluster_endpoint   = aws_eks_cluster.eks_cluster_1.endpoint
      kubeconfig-ca-data = aws_eks_cluster.eks_cluster_1.certificate_authority[0].data
    }
    nodes = {
      cluster1_nodegroup1_arn = aws_eks_node_group.cluster_1_node_group1.arn
    }
  }
}
