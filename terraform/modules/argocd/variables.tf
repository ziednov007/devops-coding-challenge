variable "argocd_version" {
  type    = string
  default = "7.4.3"
}

variable "argocd_hostname" {
  type        = string
  description = "Hostname for the ArgoCD Ingress (e.g. argocd.1.2.3.4.nip.io)"
}

variable "kube_host" {
  type = string
}

variable "kube_cert" {
  type      = string
  sensitive = true
}

variable "kube_key" {
  type      = string
  sensitive = true
}

variable "kube_ca" {
  type      = string
  sensitive = true
}
