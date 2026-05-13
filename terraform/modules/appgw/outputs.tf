output "appgw_id" {
  value = azurerm_application_gateway.this.id
}

output "waf_policy_id" {
  value = azurerm_web_application_firewall_policy.this.id
}

output "appgw_identity_id" {
  value = azurerm_user_assigned_identity.appgw.id
}

output "appgw_principal_id" {
  value = azurerm_user_assigned_identity.appgw.principal_id
}
