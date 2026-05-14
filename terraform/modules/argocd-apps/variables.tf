variable "repo_url" {
  type = string
}

variable "keyvault_id" {
  type        = string
  description = "Resource ID of the Key Vault containing app secrets"
}

variable "app_namespace" {
  type        = string
  default     = "crewmeister"
  description = "Namespace where the app runs — MySQL credentials secret is created here"
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
