provider "helm" {
  kubernetes {
    host                   = var.kube_host
    client_certificate     = base64decode(var.kube_cert)
    client_key             = base64decode(var.kube_key)
    cluster_ca_certificate = base64decode(var.kube_ca)
  }
}

provider "kubernetes" {
  host                   = var.kube_host
  client_certificate     = base64decode(var.kube_cert)
  client_key             = base64decode(var.kube_key)
  cluster_ca_certificate = base64decode(var.kube_ca)
}
