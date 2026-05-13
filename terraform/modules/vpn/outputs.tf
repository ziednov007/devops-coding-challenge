output "vpn_gateway_name" {
  value = azurerm_virtual_network_gateway.this.name
}

output "vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.this.id
}
