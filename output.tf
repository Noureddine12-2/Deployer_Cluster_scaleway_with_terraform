output "scaleway_lb_ip" {
  value = kubernetes_service.free-lb.status.0.load_balancer[0].ingress.0.ip
}
output "cluster_url" {
  value = scaleway_k8s_cluster.free-test-cluster.apiserver_url
}




