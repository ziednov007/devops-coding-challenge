resource "azurerm_kubernetes_cluster" "this" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = var.name
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "default"
    node_count                  = var.node_count
    vm_size                     = var.node_vm_size
    vnet_subnet_id              = var.aks_subnet_id
    max_pods                    = var.max_pods
    temporary_name_for_rotation = "defaulttmp"
  }

  identity { type = "SystemAssigned" }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
  }

  ingress_application_gateway {
    gateway_id = var.appgw_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}

resource "kubernetes_namespace" "app" {
  metadata {
    name   = var.app_namespace
    labels = { istio-injection = "enabled" }
  }
  lifecycle {
    ignore_changes = [metadata[0].annotations, metadata[0].labels]
  }
  depends_on = [azurerm_kubernetes_cluster.this]
}
