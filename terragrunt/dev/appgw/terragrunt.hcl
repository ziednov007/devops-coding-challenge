include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/dev.hcl")).locals }

terraform { source = "../../../terraform/modules/appgw" }

dependency "networking" {
  config_path = "../networking"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs = {
    appgw_subnet_id    = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/appgw"
    appgw_public_ip_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/publicIPAddresses/mock"
  }
}

dependency "keyvault" {
  config_path = "../keyvault"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs = {
    keyvault_id         = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock"
    appgw_ssl_secret_id = "https://mock.vault.azure.net/secrets/appgw-ssl/mock"
  }
}

inputs = {
  name                   = "${local.env.cluster_name}-appgw"
  resource_group_name    = local.env.resource_group_name
  location               = local.env.location
  appgw_subnet_id        = dependency.networking.outputs.appgw_subnet_id
  public_ip_id           = dependency.networking.outputs.appgw_public_ip_id
  keyvault_id            = dependency.keyvault.outputs.keyvault_id
  keyvault_ssl_secret_id = dependency.keyvault.outputs.appgw_ssl_secret_id
  waf_mode               = local.env.waf_mode
}
