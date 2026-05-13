include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/dev.hcl")).locals }

terraform { source = "../../../terraform/modules/rg" }

inputs = {
  name     = local.env.resource_group_name
  location = local.env.location
}
