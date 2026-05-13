# ── Root Terragrunt config ────────────────────────────────────────────────────
# All child configs inherit remote state + provider generation from here.

locals {
  # Parse env name from path: terragrunt/<env>/<module>
  env = element(compact(split("/", path_relative_to_include())), 0)
}

# Remote state: Azure Blob Storage
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "crewmeister-tfstate-rg"
    storage_account_name = "crewmeistertfstate"
    container_name       = "tfstate"
    key                  = "${local.env}/${path_relative_to_include()}/terraform.tfstate"
  }
}

# Inject provider versions into every child module
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOT
    terraform {
      required_version = ">= 1.9.0"
      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4.14"
        }
        azuread = {
          source  = "hashicorp/azuread"
          version = "~> 3.0"
        }
        helm = {
          source  = "hashicorp/helm"
          version = "~> 2.17"
        }
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.35"
        }
        tls = {
          source  = "hashicorp/tls"
          version = "~> 4.0"
        }
        time = {
          source  = "hashicorp/time"
          version = "~> 0.11"
        }
      }
    }
  EOT
}
