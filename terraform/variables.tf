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
  default     = ""
}
variable "addReceipients" {
  type = list 
  description = "additional email recipients"
}
