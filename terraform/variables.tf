variable "location"    { 
  description = "Location for services"
}

variable "kv_name"     { 
  description = "key vault name"
}  # must be globally unique

variable "pfx_password" {
  description = "PFX password"
  type        = string
  sensitive   = true
}
variable "addReceipients" {
  type = list 
  description = "additional email recipients"
}

variable "display_name" { 
  default = "Openfire Bind" 
  description = "Display name for Openfire bind user"
}

# Optional: set to an existing Key Vault ID to store the password
# e.g. "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/kv-o4j-aadds-001"
variable "key_vault_id" {
  type        = string
  default     = ""
  description = "Existing Key Vault ID to store the service account password (optional). Leave empty to skip."
}

variable "openfire_user_name"   { 
  default = "openfire-bind" 
  description = "User name for openfire bind"
}
