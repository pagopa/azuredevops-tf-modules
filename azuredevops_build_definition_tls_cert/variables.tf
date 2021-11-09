variable "project_id" {
  type        = string
  description = "(Required) Azure DevOps project ID"
}

variable "repository" {
  type = object({
    organization   = string
    name           = string
    branch_name    = string
    pipelines_path = string
  })
  description = "(Required) GitHub repository attributes"
}

variable "renew_token" {
  type        = string
  description = "(Required) Renew token to recreate service principal. Change it to renew service principal credentials"
}

variable "name" {
  type        = string
  description = "(Required) Pipeline name equals to domain name"
}

variable "path" {
  type        = string
  description = "(Required) Pipeline path on Azure DevOps"
}

variable "github_service_connection_id" {
  type        = string
  description = "(Required) GitHub service connection ID used to link Azure DevOps."
}

variable "variables" {
  type        = map(any)
  default     = null
  description = "(Optional) Pipeline variables"
}

variable "variables_secret" {
  type        = map(any)
  default     = null
  description = "(Optional) Pipeline secret variables"
}

variable "service_connection_ids_authorization" {
  type        = list(string)
  default     = null
  description = "(Optional) List service connection IDs that pipeline needs authorization. github_service_connection_id is authorized by default"
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
  description = "(Required) key vault where store service principal credentials"
}

variable "credential_key_vault_resource_group" {
  type        = string
  description = "(Required) key vault resource group where store service principal credentials"
}

variable "dns_record_name" {
  type        = string
  description = "(Required) Dns record name"
}

variable "dns_zone_name" {
  type        = string
  description = "(Required) Dns zone name"
}

variable "dns_zone_resource_group" {
  type        = string
  description = "(Required) Dns zone resource group name"
}
