include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/prod.hcl")).locals }

terraform { source = "../../../terraform/modules/aks" }

dependency "networking" {
  config_path = "../networking"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs = {
    aks_subnet_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/aks"
  }
}

dependency "appgw" {
  config_path = "../appgw"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs = {
    appgw_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/applicationGateways/mock"
  }
}

inputs = {
  name                = local.env.cluster_name
  resource_group_name = local.env.resource_group_name
  location            = local.env.location
  aks_subnet_id       = dependency.networking.outputs.aks_subnet_id
  appgw_id            = dependency.appgw.outputs.appgw_id
  node_count          = local.env.node_count
  node_vm_size        = local.env.node_vm_size
  app_namespace       = local.env.app_namespace
}
