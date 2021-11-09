
# Cluster 1 deployments
resource "kubernetes_deployment" "cluster_1_service_A_node_group_1" {
  provider = kubernetes.cluster_1
  metadata {
    name = "cluster-1-service-a-ng1"
    labels = {
      App = "ServiceA"
      customSG = "true"
    }
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        App = "ServiceA"
      }
    }
    template {
      metadata {
        labels = {
          App = "ServiceA"
        }
      }
      spec {
        container {
          image = var.serviceA_container_image
          name  = "service-a"

          port {
            container_port = 20
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
        node_selector = {
          "eks.amazonaws.com/nodegroup" = "${aws_eks_node_group.cluster_1_node_group1.node_group_name}"
        }
      }
    }
  }

  depends_on = [
    null_resource.annotate_nodes,
    aws_eks_node_group.cluster_1_node_group1
  ]
}

resource "kubernetes_deployment" "cluster_1_service_B_node_group_1" {
  provider = kubernetes.cluster_1
  metadata {
    name = "cluster-1-service-b-ng1"
    labels = {
      App = "ServiceB"
      customSG = "true"
    }
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        App = "ServiceB"
      }
    }
    template {
      metadata {
        labels = {
          App = "ServiceB"
        }
      }
      spec {
        container {
          image = var.serviceB_container_image
          name  = "service-b"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
        node_selector = {
          "eks.amazonaws.com/nodegroup" = "${aws_eks_node_group.cluster_1_node_group1.node_group_name}"
        }
      }
    }
  }

  depends_on = [
    null_resource.annotate_nodes,
    aws_eks_node_group.cluster_1_node_group1
  ]
}