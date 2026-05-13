locals {
  env                  = "dev"
  location             = "austriaeast"
  resource_group_name  = "crewmeister-dev-rg"
  cluster_name         = "crewmeister-dev-aks"
  keyvault_name        = "crewmeister-dev-kv"
  app_namespace        = "crewmeister"
  node_count           = 2
  node_vm_size         = "Standard_D2_v3"
  repo_url             = "https://github.com/ziednov007/devops-coding-challenge"
  waf_mode             = "Detection"   # less strict in dev
  vpn_client_cidr      = "172.16.0.0/24"
}
