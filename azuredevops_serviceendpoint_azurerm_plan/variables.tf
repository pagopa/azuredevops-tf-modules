locals {
  plan_app_roles = {
    permissions = [
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

variable "name" {
  type        = string
  description = "(Required) Service principal name"
}

variable "project_id" {
  type        = string
  description = "(Required) Azure DevOps project ID"
}

variable "renew_token" {
  type        = string
  description = "(Required) Renew token to recreate service principal. Change it to renew service principal credentials"
}

variable "subscription_name" {
  type        = string
  description = "(Required) Azure Subscription name related to tenant where create service principal"
}

variable "subscription_id" {
  type        = string
  description = "(Required) Azure Subscription ID related to tenant where create service principal"
}

variable "tenant_id" {
  type        = string
  description = "(Required) Azure Tenant ID related to tenant where create service principal"
}

variable "credential_subcription" {
  type        = string
  description = "(Required) Azure Subscription where store service principal credentials"
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

variable "custom_role_name" {
  type        = string
  description = "Custom role that allows IaC SP to read resources and generate kubernetes credentials"
  default     = "PagoPA IaC Reader"
}

variable "password_time_rotation_days" {
  type = number
  description = "How many days before the password(credentials) is rotated"
  default = 365
}

variable "iac_aad_group_name" {
  type        = string
  description = "Azure AD group name for iac sp apps (with Directory Reader permissions at leats)"
}
