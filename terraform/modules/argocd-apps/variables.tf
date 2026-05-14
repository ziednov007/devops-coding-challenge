variable "repo_url" {
  type = string
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
