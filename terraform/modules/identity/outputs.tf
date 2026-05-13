output "app_identity_id" {
  value = azurerm_user_assigned_identity.app.id
}

output "app_identity_client_id" {
  value = azurerm_user_assigned_identity.app.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
