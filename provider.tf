terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  access_key      = var.ACCESSKEY
  secret_key      = var.SECRETKEY
  organization_id = var.PROJECTID
  region          = var.REGION
  zone            = var.ZONE1
}

provider "kubernetes" {
  host  = scaleway_k8s_cluster.free-test-cluster.apiserver_url
  token = null_resource.kubeconfig.triggers.token
  cluster_ca_certificate = base64decode(
    null_resource.kubeconfig.triggers.cluster_ca_certificate
  )
}
provider "helm" {
  kubernetes {
    host  = null_resource.kubeconfig.triggers.host
    token = null_resource.kubeconfig.triggers.token
    cluster_ca_certificate = base64decode(
      null_resource.kubeconfig.triggers.cluster_ca_certificate
    )
  }
}
