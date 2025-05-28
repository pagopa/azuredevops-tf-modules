variable "location" {
  type = string
}

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

variable "agent_pool_name" {
  type        = string
  default     = "Azure Pipelines"
  description = "The agent pool that should execute the build"
}

variable "path" {
  type        = string
  description = "(Required) Pipeline path on Azure DevOps"
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

variable "repository_repo_type" {
  type        = string
  description = " (Optional) The repository type. Valid values: GitHub or GitHub Enterprise. Defaults to GitHub. If repo_type is GitHubEnterprise, must use existing project and GitHub Enterprise service connection."
  default     = "GitHub"
}

variable "github_service_connection_id" {
  type        = string
  description = "(Required) GitHub service connection ID used to link Azure DevOps."
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

#
# 🔒 KV
#
variable "credential_key_vault_name" {
  type        = string
  description = "(Required) key vault where store service principal credentials"
}

variable "credential_key_vault_resource_group" {
  type        = string
  description = "(Required) key vault resource group where store service principal credentials"
}

#
# DNS
#
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

variable "managed_identity_resource_group_name" {
  type        = string
  description = "(Required) Managed identity resource group, where will be created"
}

variable "cert_name_expire_seconds" {
  type        = number
  description = "(Optional) Certficate expire in seconds. Default is '2592000' #30 days"
  default     = 2592000
}

variable "schedules" {
  type = object({
    days_to_build              = list(string)
    schedule_only_with_changes = bool
    start_hours                = number
    start_minutes              = number
    time_zone                  = string
    branch_filter = object({
      include = list(string)
      exclude = list(string)
    })
  })
  default = {
    days_to_build              = ["Fri"]
    schedule_only_with_changes = false
    start_hours                = 1
    start_minutes              = 0
    time_zone                  = "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"
    branch_filter = {
      include = ["main", "master"]
      exclude = []
    }
  }
  description = "Allow to setup schedules trigger in azure devops. Usign that the schedules used in the yaml will be disabled"
}

variable "cert_diff_variables" {
  type = object({
    enabled           = bool
    alert_enabled     = bool
    cert_diff_version = string
    app_insights_name = optional(string)
    app_insights_rg   = optional(string)
    actions_group     = optional(list(string))
  })
  default = {
    enabled           = false
    alert_enabled     = false
    cert_diff_version = "0.2.5"
  }
  description = "(Optional) Cert diff pipeline variables"
}
