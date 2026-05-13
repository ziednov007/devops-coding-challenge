variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "app_namespace" {
  type = string
}

variable "app_service_account" {
  type    = string
  default = "crewmeister-challenge"
}

variable "oidc_issuer_url" {
  type = string
}

variable "agic_object_id" {
  type = string
}

variable "appgw_id" {
  type = string
}

variable "appgw_principal_id" {
  type = string
}

variable "aks_identity_principal_id" {
  type        = string
  description = "Principal ID of the AKS cluster system-assigned identity (needed for VNet Network Contributor)"
}

variable "vnet_id" {
  type        = string
  description = "Resource ID of the VNet — AKS identity gets Network Contributor to manage internal LBs"
}
