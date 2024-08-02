locals {
  default_audience_name        = "api://AzureADTokenExchange"
  serviceendpoint_azurerm_name = "${upper(var.serviceendpoint_azurecr_name_prefix)}-SERVICE-CONN"
}

variable "location" {
  type = string
}

variable "serviceendpoint_azurecr_name_prefix" {
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

### ACR

variable "azurecr_resource_group_name" {
  type        = string
  description = "Resource group name where the ACR is installed"
}

variable "azurecr_name" {
  type        = string
  description = "ACR's name"
}
