data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Grant the Terraform caller KV Administrator so it can write secrets/certs
resource "azurerm_role_assignment" "terraform_kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC propagation in Azure takes up to 2 minutes
resource "time_sleep" "kv_rbac" {
  depends_on      = [azurerm_role_assignment.terraform_kv_admin]
  create_duration = "90s"
}

# ── Self-signed TLS certificate (PFX) for Application Gateway ─────────────────
resource "azurerm_key_vault_certificate" "appgw_ssl" {
  depends_on   = [time_sleep.kv_rbac]
  name         = "appgw-ssl"
  key_vault_id = azurerm_key_vault.this.id

  certificate_policy {
    issuer_parameters { name = "Self" }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    lifetime_action {
      action { action_type = "AutoRenew" }
      trigger { days_before_expiry = 30 }
    }
    secret_properties { content_type = "application/x-pkcs12" }
    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
      key_usage          = ["cRLSign", "dataEncipherment", "digitalSignature", "keyAgreement", "keyEncipherment", "keyCertSign"]
      subject            = "CN=crewmeister.internal, O=Crewmeister"
      validity_in_months = 12
      subject_alternative_names {
        dns_names = ["crewmeister.internal", "*.crewmeister.internal"]
      }
    }
  }
}

# ── TLS PEM secrets (used by cert-manager / Istio) ────────────────────────────
resource "tls_private_key" "ssl" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ssl" {
  private_key_pem   = tls_private_key.ssl.private_key_pem
  is_ca_certificate = false
  subject {
    common_name  = "crewmeister.internal"
    organization = "Crewmeister"
  }
  validity_period_hours = 8760
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]
  dns_names             = ["crewmeister.internal", "*.crewmeister.internal"]
}

resource "azurerm_key_vault_secret" "tls_cert" {
  depends_on   = [time_sleep.kv_rbac]
  name         = "tls-cert"
  value        = tls_self_signed_cert.ssl.cert_pem
  key_vault_id = azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "tls_key" {
  depends_on   = [time_sleep.kv_rbac]
  name         = "tls-key"
  value        = tls_private_key.ssl.private_key_pem
  key_vault_id = azurerm_key_vault.this.id
  lifecycle { ignore_changes = [value] }
}

resource "azurerm_key_vault_secret" "mysql_password" {
  depends_on   = [time_sleep.kv_rbac]
  name         = "mysql-password"
  value        = var.mysql_password
  key_vault_id = azurerm_key_vault.this.id
}
