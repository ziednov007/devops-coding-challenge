variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/8"
}

variable "aks_subnet_cidr" {
  type    = string
  default = "10.240.0.0/16"
}

variable "appgw_subnet_cidr" {
  type    = string
  default = "10.2.0.0/24"
}

variable "gateway_subnet_cidr" {
  type    = string
  default = "10.3.0.0/27"
}

variable "vpn_client_cidr" {
  type    = string
  default = "172.16.0.0/24"
}
