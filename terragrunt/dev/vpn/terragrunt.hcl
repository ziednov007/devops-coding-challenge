skip = true

include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/dev.hcl")).locals }

terraform { source = "../../../terraform/modules/vpn" }

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    gateway_subnet_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/GatewaySubnet"
  }
}

dependency "keyvault" {
  config_path = "../keyvault"
  mock_outputs = { keyvault_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock" }
}

inputs = {
  name                = local.env.cluster_name
  resource_group_name = local.env.resource_group_name
  location            = local.env.location
  gateway_subnet_id   = dependency.networking.outputs.gateway_subnet_id
  vpn_client_cidr     = local.env.vpn_client_cidr
  keyvault_id         = dependency.keyvault.outputs.keyvault_id
}
