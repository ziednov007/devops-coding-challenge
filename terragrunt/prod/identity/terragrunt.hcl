include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/prod.hcl")).locals }

terraform { source = "../../../terraform/modules/identity" }

dependency "keyvault" {
  config_path = "../keyvault"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = { keyvault_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock" }
}

dependency "aks" {
  config_path = "../aks"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    oidc_issuer_url              = "https://mock.oidc.issuer"
    agic_object_id               = "00000000-0000-0000-0000-000000000000"
    cluster_identity_principal_id = "00000000-0000-0000-0000-000000000000"
  }
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vnet_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock"
  }
}

dependency "appgw" {
  config_path = "../appgw"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    appgw_id           = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/applicationGateways/mock"
    appgw_principal_id = "00000000-0000-0000-0000-000000000000"
  }
}

inputs = {
  name                = local.env.cluster_name
  resource_group_name = local.env.resource_group_name
  location            = local.env.location
  resource_group_id   = "/subscriptions/${get_env("ARM_SUBSCRIPTION_ID")}/resourceGroups/${local.env.resource_group_name}"
  keyvault_id         = dependency.keyvault.outputs.keyvault_id
  oidc_issuer_url              = dependency.aks.outputs.oidc_issuer_url
  agic_object_id               = dependency.aks.outputs.agic_object_id
  cluster_identity_principal_id = dependency.aks.outputs.cluster_identity_principal_id
  appgw_id                     = dependency.appgw.outputs.appgw_id
  appgw_principal_id           = dependency.appgw.outputs.appgw_principal_id
  app_namespace                = local.env.app_namespace
  vnet_id                      = dependency.networking.outputs.vnet_id
}
