resource "scaleway_k8s_cluster" "free-test-cluster" {
  name                        = "test-cluster"
  cni                         = "flannel"
  version                     = "1.24.3"
  region                      = "fr-par"
  delete_additional_resources = false
}

resource "scaleway_k8s_pool" "test-pool" {
  cluster_id = scaleway_k8s_cluster.free-test-cluster.id
  name       = "hello-world"
  node_type  = "DEV1-M"
  size       = 1
}
resource "null_resource" "kubeconfig" {
  depends_on = [scaleway_k8s_pool.test-pool] # at least one pool here
  triggers = {
    host                   = scaleway_k8s_cluster.free-test-cluster.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.free-test-cluster.kubeconfig[0].token
    cluster_ca_certificate = scaleway_k8s_cluster.free-test-cluster.kubeconfig[0].cluster_ca_certificate
  }
}



## Création de nginx ingress et attacher le load balancer free-lb dans notre ingress

resource "helm_release" "nginx_ingress" {

  name      = "nginx-ingress"
  namespace = "kube-system"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set {
    name  = "controller.service.loadBalancerIP"
    value = kubernetes_service.free-lb.status.0.load_balancer[0].ingress.0.ip
  }


  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/scw-loadbalancer-zone"
    value = var.ZONE1
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

}






#Éxecuter le container hello-world dans un pod en utilisant kubernet object (deployment)

resource "kubernetes_deployment" "hello-world" {
  metadata {
    name = "hello-world"
    labels = {
      App = "hello-world"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "run-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "run-app"
        }
      }
      spec {
        container {
          image = "docker.io/strm/helloworld-http:latest"
          name  = "hello-world"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "2"
              memory = "256Mi"
            }
            requests = {
              cpu    = "16m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "free-lb" {
  metadata {
    name = "free-lb"
    labels = {
      app = "run-app"
    }
  }

  spec {
    selector = {
      app = "run-app"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}


