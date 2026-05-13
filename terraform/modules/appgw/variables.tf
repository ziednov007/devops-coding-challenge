variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "appgw_subnet_id" {
  type = string
}

variable "public_ip_id" {
  type = string
}

variable "keyvault_ssl_secret_id" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
}

variable "keyvault_cert_role_dep" {
  description = "Dependency handle — Terraform waits for the KV Certificate User role before creating the gateway"
  type        = any
  default     = null
}
