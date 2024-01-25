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
