variable "subscription_id" {
  type    = string
  default = ""
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}
