data "azurerm_client_config" "current" {}

# ── App workload identity ─────────────────────────────────────────────────────
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.name}-app-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "app" {
  name                = "${var.name}-app-federated"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.app.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${var.app_namespace}:${var.app_service_account}"
}

# ── Role assignments ──────────────────────────────────────────────────────────

# AGIC (managed by AKS addon) needs to control the Application Gateway
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = var.appgw_id
  role_definition_name = "Contributor"
  principal_id         = var.agic_object_id
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = var.resource_group_id
  role_definition_name = "Reader"
  principal_id         = var.agic_object_id
}

# AGIC requires Managed Identity Operator on the AppGW UAMI to update the gateway
# without this the CreateOrUpdate call returns 403 LinkedAuthorizationFailed
resource "azurerm_role_assignment" "agic_appgw_uami_operator" {
  scope                = var.appgw_identity_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.agic_object_id
}

# AKS cluster identity needs Network Contributor on the VNet to manage internal LBs
resource "azurerm_role_assignment" "aks_vnet_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_identity_principal_id
}

# App pods read secrets from Key Vault via Workload Identity
resource "azurerm_role_assignment" "app_kv_secrets" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
