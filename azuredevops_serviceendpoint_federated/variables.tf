locals {
  default_audience_name = "api://AzureADTokenExchange"
}

variable "location" {
  type = string
}

variable "name" {
  type        = string
  description = "(Required) Service principal name"
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
