include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/dev.hcl")).locals }

terraform { source = "../../../terraform/modules/keyvault" }

dependency "rg" {
  config_path  = "../rg"
  skip_outputs = true
}

inputs = {
  name                = local.env.keyvault_name
  resource_group_name = local.env.resource_group_name
  location            = local.env.location
  tenant_id           = get_env("ARM_TENANT_ID")
  mysql_password      = get_env("TF_VAR_MYSQL_PASSWORD")
}
