include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/dev.hcl")).locals }

terraform { source = "../../../terraform/modules/argocd" }

dependency "aks" {
  config_path = "../aks"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    kube_config = {
      host                   = "https://mock"
      client_certificate     = "bW9jaw=="
      client_key             = "bW9jaw=="
      cluster_ca_certificate = "bW9jaw=="
    }
  }
}

inputs = {
  kube_host = dependency.aks.outputs.kube_config.host
  kube_cert = dependency.aks.outputs.kube_config.client_certificate
  kube_key  = dependency.aks.outputs.kube_config.client_key
  kube_ca   = dependency.aks.outputs.kube_config.cluster_ca_certificate
}
