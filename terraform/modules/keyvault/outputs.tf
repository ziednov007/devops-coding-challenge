output "keyvault_id" {
  value = azurerm_key_vault.this.id
}

output "keyvault_name" {
  value = azurerm_key_vault.this.name
}

output "tenant_id" {
  value = azurerm_key_vault.this.tenant_id
}

output "appgw_ssl_secret_id" {
  value = azurerm_key_vault_certificate.appgw_ssl.secret_id
}
