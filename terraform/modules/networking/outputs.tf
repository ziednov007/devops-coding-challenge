output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "appgw_public_ip_id" {
  value = azurerm_public_ip.appgw.id
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "vpn_public_ip_id" {
  value = azurerm_public_ip.vpn.id
}
