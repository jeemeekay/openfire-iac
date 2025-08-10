data "azurerm_client_config" "me" {}

module "entra_domain_services" {
  source = "git::https://github.com/jeemeekay/terraform-azapi-entra-domain-services.git?ref=v0.0.8"

  # Note: domain must either be the tenant's domain or a custom domain registered and verified in EID
  domain = data.azuread_domains.default.domains.1.domain_name
  subnet = azurerm_subnet.deploy
  notification_settings = {
    additionalRecipients = var.addReceipients
    notifyAADDCAdmins    = true
    notifyGlobalAdmins   = false
  }
  ldaps_settings = {
    externalAccess         = true
    pfxCertificate         = azurerm_key_vault_secret.wildcard_pfx.value
    pfxCertificatePassword = var.pfx_password

  }
  security_settings = {
    channelBinding        = true
    kerberosArmoring      = true
    kerberosRc4Encryption = true
  }
  location               = var.location
  resource_group_id      = azurerm_resource_group.deploy.id
  network_security_group = azurerm_network_security_group.deploy
}


resource "azurerm_key_vault" "kv" {
  name                        = var.kv_name
  location                    = azurerm_resource_group.deploy.location
  resource_group_name         = azurerm_resource_group.deploy.name
  tenant_id                   = data.azurerm_client_config.me.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90

  access_policy {
    tenant_id = data.azurerm_client_config.me.tenant_id
    object_id = data.azurerm_client_config.me.object_id
    secret_permissions = ["Get","List","Set","Delete","Purge","Recover"]
  }
}

############################
# Upload wildcard PFX to KV
############################
resource "azurerm_key_vault_secret" "wildcard_pfx" {
  name         = "multi-o4j-pfx"
  key_vault_id = azurerm_key_vault.kv.id
  value        = filebase64("${path.module}/data/wildcard_o4j_co_uk.pfx")  # store binary as base64
  content_type = "application/x-pkcs12"
}

resource "azurerm_key_vault_secret" "wildcard_pfx_password" {
  name         = "multi-o4j-pfx-password"
  key_vault_id = azurerm_key_vault.kv.id
  value        = var.pfx_password
}
