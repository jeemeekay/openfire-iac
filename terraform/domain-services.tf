module "entra_domain_services" {
  source = "git::https://github.com/jeemeekay/terraform-azapi-entra-domain-services.git?ref=v0.0.5"

  # Note: domain must either be the tenant's domain or a custom domain registered and verified in EID
  domain = data.azuread_domains.default.domains.1.domain_name
  subnet = azurerm_subnet.deploy
  notification_settings = {
    additionalRecipients = ["kayode@o4j.co.uk" ]
    notifyAADDCAdmins    = true
    notifyGlobalAdmins   = false
  }
  ldaps_settings = null
  security_settings = {
    channelBinding        = true
    kerberosArmoring      = true
    kerberosRc4Encryption = true
  }
  location               = "West Europe"
  resource_group_id      = azurerm_resource_group.deploy.id
  network_security_group = azurerm_network_security_group.deploy
}