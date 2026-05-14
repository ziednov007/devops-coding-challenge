# ── AppGW User-Assigned Managed Identity (owns its own UAMI — no circular dep) ─
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# AppGW UAMI needs Key Vault Certificate User before the gateway can read the SSL cert
resource "azurerm_role_assignment" "appgw_kv_cert" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

resource "time_sleep" "appgw_kv_rbac" {
  depends_on      = [azurerm_role_assignment.appgw_kv_cert]
  create_duration = "90s"
}

# ── WAF Policy (OWASP 3.2 + Bot Manager, custom rate-limit) ──────────────────
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
    }
  }

}

# ── Application Gateway WAF_v2 ────────────────────────────────────────────────
locals {
  fe_ip          = "public-fe-ip"
  fe_https       = "port-443"
  fe_http        = "port-80"
  pool           = "default-pool"
  http_settings  = "default-http"
  https_listener = "https-listener"
  http_listener  = "http-listener"
  https_rule     = "https-rule"
  redirect_rule  = "http-to-https-rule"
  ssl_cert       = "appgw-ssl"
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gw-ip"
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.fe_ip
    public_ip_address_id = var.public_ip_id
  }

  frontend_port {
    name = local.fe_https
    port = 443
  }

  frontend_port {
    name = local.fe_http
    port = 80
  }

  ssl_certificate {
    name                = local.ssl_cert
    key_vault_secret_id = var.keyvault_ssl_secret_id
  }

  backend_address_pool { name = local.pool }

  backend_http_settings {
    name                  = local.http_settings
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.https_listener
    frontend_ip_configuration_name = local.fe_ip
    frontend_port_name             = local.fe_https
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_cert
    firewall_policy_id             = azurerm_web_application_firewall_policy.this.id
  }

  http_listener {
    name                           = local.http_listener
    frontend_ip_configuration_name = local.fe_ip
    frontend_port_name             = local.fe_http
    protocol                       = "Http"
  }

  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = local.https_listener
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                       = local.https_rule
    rule_type                  = "Basic"
    http_listener_name         = local.https_listener
    backend_address_pool_name  = local.pool
    backend_http_settings_name = local.http_settings
    priority                   = 10
  }

  request_routing_rule {
    name                        = local.redirect_rule
    rule_type                   = "Basic"
    http_listener_name          = local.http_listener
    redirect_configuration_name = "http-to-https"
    priority                    = 20
  }

  depends_on = [time_sleep.appgw_kv_rbac]

  lifecycle {
    ignore_changes = [
      backend_address_pool, backend_http_settings,
      frontend_port,
      http_listener, probe, request_routing_rule,
      redirect_configuration, url_path_map, tags,
    ]
  }
}
