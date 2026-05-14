include "root" { path = find_in_parent_folders() }

locals { env = read_terragrunt_config(find_in_parent_folders("_env/dev.hcl")).locals }

terraform { source = "../../../terraform/modules/argocd-apps" }

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

dependency "argocd" {
  config_path = "../argocd"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = { argocd_namespace = "argocd" }
  skip_outputs = true
}

dependency "identity" {
  config_path = "../identity"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = { app_identity_client_id = "00000000-0000-0000-0000-000000000000" }
}

inputs = {
  repo_url               = local.env.repo_url
  kube_host              = dependency.aks.outputs.kube_config.host
  kube_cert              = dependency.aks.outputs.kube_config.client_certificate
  kube_key               = dependency.aks.outputs.kube_config.client_key
  kube_ca                = dependency.aks.outputs.kube_config.cluster_ca_certificate
  app_identity_client_id = dependency.identity.outputs.app_identity_client_id
}
