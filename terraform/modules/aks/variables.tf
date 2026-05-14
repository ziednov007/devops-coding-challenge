variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "appgw_id" {
  type = string
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "max_pods" {
  type    = number
  default = 110
}

variable "app_namespace" {
  type    = string
  default = "crewmeister"
}
