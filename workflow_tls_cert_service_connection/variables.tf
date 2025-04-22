variable "env_short" {
  description = "Environment (d, u, p)"
  type        = string
}

variable "prefix" {
  description = "Resource prefix"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "azdo_project_id" {
  description = "Azure DevOps project id (must be a GUID)"
  type        = string
}

variable "identity_name" {
  description = "Service connection resource name"
  type        = string
}

variable "identity_resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault id (must be a GUID)"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
}

variable "tenant_id" {
  description = "Tenant id (must be a GUID)"
  type        = string
}

variable "subscription_name" {
  description = "Subscription name"
  type        = string
}

variable "subscription_id" {
  description = "Subscription id (must be a GUID)"
  type        = string
}

#
# Flags
#
variable "letsencrypt_credential_enabled" {
  description = "Enable letsencrypt credential"
  type        = bool
  default     = true
}

variable "tls_cert_service_conn_enabled" {
  description = "Enable TLS cert service connection"
  type        = bool
  default     = true
}
