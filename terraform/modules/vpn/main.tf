resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true
  subject {
    common_name  = "Crewmeister VPN CA"
    organization = "Crewmeister"
  }
  validity_period_hours = 87600
  allowed_uses          = ["cert_signing", "crl_signing"]
}

resource "azurerm_key_vault_secret" "vpn_ca_cert" {
  name         = "vpn-ca-cert"
  value        = tls_self_signed_cert.ca.cert_pem
  key_vault_id = var.keyvault_id
}

resource "azurerm_key_vault_secret" "vpn_ca_key" {
  name         = "vpn-ca-key"
  value        = tls_private_key.ca.private_key_pem
  key_vault_id = var.keyvault_id
  lifecycle { ignore_changes = [value] }
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "${var.name}-vpn-gw"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vpn-ip-config"
    public_ip_address_id          = var.public_ip_id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  vpn_client_configuration {
    address_space        = [var.vpn_client_cidr]
    vpn_client_protocols = ["OpenVPN", "IkeV2"]

    root_certificate {
      name = "crewmeister-vpn-ca"
      public_cert_data = base64encode(
        trimspace(replace(replace(
          tls_self_signed_cert.ca.cert_pem,
          "-----BEGIN CERTIFICATE-----\n", ""
        ), "\n-----END CERTIFICATE-----", ""))
      )
    }
  }
}
