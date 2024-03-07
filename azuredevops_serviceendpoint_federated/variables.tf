locals {
  default_audience_name        = "api://AzureADTokenExchange"
  serviceendpoint_azurerm_name = var.serviceendpoint_azurerm_name != "" ? "${upper(var.serviceendpoint_azurerm_name)}-SERVICE-CONN" : "${upper(var.name)}-SERVICE-CONN"
}

variable "location" {
  type = string
}

variable "name" {
  type        = string
  description = "(Required) Managed identity & Service connection name (if not defined `serviceendpoint_azurerm_name`)"
}

variable "serviceendpoint_azurerm_name" {
  type        = string
  description = "(Optional) Service connection azurerm name"
  default     = ""
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the managed identity will be create"
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

variable "subscription_name" {
  type        = string
  description = "(Required) Azure Subscription name related to tenant where create service principal"
}

variable "default_roleassignment_rg_prefix" {
  type        = string
  default     = ""
  description = "(Optional) Add a prefix to default_roleassignment_rg"
}

variable "check_approval_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Flag to approve use of the service connection"
}

variable "approver_ids" {
  type        = list(string)
  default     = []
  description = "(Optional) Credential IDs for approving the use of the service connection"
}
