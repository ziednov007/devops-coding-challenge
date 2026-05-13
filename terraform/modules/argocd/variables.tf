variable "argocd_version" {
  type    = string
  default = "7.4.3"
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
