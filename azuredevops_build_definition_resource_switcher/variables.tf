variable "project_id" {
  type        = string
  description = "(Required) Azure DevOps project ID"
}

variable "repository" {
  type = object({
    organization    = string
    name            = string
    branch_name     = string
    pipelines_path  = string
    yml_prefix_name = string
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
  default     = []
  description = "(Optional) List service connection IDs that pipeline needs authorization. github_service_connection_id is authorized by default"
}


variable "subscription_id" {
  type        = string
  description = "(Required) Azure Subscription ID related to tenant where create service principal"
}

variable "tenant_id" {
  type        = string
  description = "(Required) Azure Tenant ID related to tenant where create service principal"
}

variable "schedule_configuration" {
  type = object({
    days_to_build = list(string)
    timezone      = string
    branch_filter = object({
      include = list(string)
      exclude = list(string)
    })
    aks = list(object({
      cluster_name = string
      start_time   = string
      stop_time    = string
      rg           = string
      user = object({
        nodes_on_start = string
        nodes_on_stop  = string
      })
      system = object({
        nodes_on_start = string
        nodes_on_stop  = string
      })
    }))
  })
  description = "(Required) structure defining which service to manage, when and how. See README.md for details"
  validation {
    condition = alltrue(
        flatten([
          for s in var.schedule_configuration.aks : [
            length(split(",", s.user.nodes_on_start)) == 2,
            length(split(",", s.user.nodes_on_stop)) == 2,
            length(split(",", s.system.nodes_on_start)) == 2,
            length(split(",", s.system.nodes_on_stop)) == 2
          ]
        ])
      )
    error_message = "Number of nodes configured is not valid (nodes_on_start, nodes_on_stop). The expected format is <min>,<max>"
  }
}
