########################
# Outputs
########################
output "bind_upn" {
  value       = azuread_user.openfire_bind.user_principal_name
  description = "Use this as the bind DN (UPN) in Openfire."
}

output "bind_password" {
  value       = random_password.svc_pwd.result
  sensitive   = true
  description = "Password (also stored in Key Vault if key_vault_id was provided)."
}

output "bind_distinguished_name_hint" {
  value       = "CN=${var.display_name},OU=AADDC Users,DC=azure,DC=o4j,DC=co,DC=uk"
  description = "If Openfire needs a DN instead of UPN, this is the typical DN in AAD DS."
}

output "entra_domain_output" {
  value = module.entra_domain_services.entra_domain_output
  description = "json output from entra domain service module"
}