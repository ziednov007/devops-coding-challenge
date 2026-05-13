variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "gateway_subnet_id" {
  type = string
}

variable "public_ip_id" {
  type = string
}

variable "vpn_client_cidr" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "terraform_kv_role_dep" {
  type    = string
  default = ""
}
