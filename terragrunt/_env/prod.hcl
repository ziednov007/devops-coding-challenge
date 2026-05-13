locals {
  env                  = "prod"
  location             = "germanywestcentral"
  resource_group_name  = "crewmeister-prod-rg"
  cluster_name         = "crewmeister-prod-aks"
  keyvault_name        = "crewmeister-prod-kv"
  app_namespace        = "crewmeister"
  node_count           = 2
  node_vm_size         = "Standard_DC2as_v5"
  repo_url             = "https://github.com/ziednov007/devops-coding-challenge"
  waf_mode             = "Prevention"  # blocking in prod
  vpn_client_cidr      = "172.17.0.0/24"
}
