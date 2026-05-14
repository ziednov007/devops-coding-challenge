provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = var.kube_host
  client_certificate     = base64decode(var.kube_cert)
  client_key             = base64decode(var.kube_key)
  cluster_ca_certificate = base64decode(var.kube_ca)
}
