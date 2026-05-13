include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/prod.hcl")).locals }

terraform { source = "../../../terraform/modules/networking" }

dependency "rg" {
  config_path  = "../rg"
  skip_outputs = true
}

inputs = {
  name                = local.env.cluster_name
  resource_group_name = local.env.resource_group_name
  location            = local.env.location
  vpn_client_cidr     = local.env.vpn_client_cidr
}
