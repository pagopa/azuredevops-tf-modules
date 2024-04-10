locals {
  app_name = "azdo-sp-plan-${var.name_suffix}"

  plan_app_roles = {
    permissions = [
      "PagoPA IaC Reader",
      "Reader",
      "Reader and Data Access",
      "Storage Blob Data Reader",
      "Storage File Data SMB Share Reader",
      "Storage Queue Data Reader",
      "Storage Table Data Reader",
      "PagoPA Export Deployments Template",
      "Key Vault Secrets User",
      "DocumentDB Account Contributor",
      "API Management Service Contributor",
    ]
  }
}

variable "name_suffix" {
  type        = string
  description = "(Required) Service principal name suffix"
}

variable "project_id" {
  type        = string
  description = "(Required) Azure DevOps project ID"
}

variable "subscription_id" {
  type        = string
  description = "(Required) Azure Subscription ID related to tenant where create service principal"
}

variable "tenant_id" {
  type        = string
  description = "(Required) Azure Tenant ID related to tenant where create service principal"
}

variable "credential_key_vault_name" {
  type        = string
  description = "(Required) Key vault name where store service principal credentials"
}

variable "credential_key_vault_resource_group" {
  type        = string
  description = "(Required) Key vault resource group where store service principal credentials"
}

variable "default_roleassignment_rg_prefix" {
  type        = string
  default     = ""
  description = "(Optional) Add a prefix to default_roleassignment_rg"
}

variable "password_time_rotation_days" {
  type        = number
  description = "How many days before the password(credentials) is rotated"
  default     = 365
}

variable "default_resource_group_name" {
  type        = string
  description = "The name of the default resource group to link with the new app to allow the connection"
  default     = "default-roleassignment-rg"
}

variable "renew_token" {
  type        = string
  description = "(Optional) Renew token to recreate service principal. Change it to renew service principal credentials"
  default     = "v1"
}
