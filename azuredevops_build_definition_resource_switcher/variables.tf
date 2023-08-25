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
  default = {
    organization    = "pagopa"
    name            = "eng-common-scripts"
    branch_name     = "refs/heads/main"
    pipelines_path  = "devops"
    yml_prefix_name = null
  }
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


variable "timeout" {
  type        = number
  description = "(Optional) Switcher pipeline timeout, in minutes"
  default     = 30
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
      cluster_name         = string
      start_time           = string
      stop_time            = string
      rg                   = string
      force                = optional(bool, false)
      node_pool_exclusions = optional(list(string), [])
      user = object({
        nodes_on_start = string
        nodes_on_stop  = string
      })
      system = object({
        nodes_on_start = string
        nodes_on_stop  = string
      })
    }))
    sa_sftp = list(object({
      start_time = string
      stop_time  = string
      sa_name    = string
    }))
  })
  description = "(Required) structure defining which service to manage, when and how. See README.md for details"
  default = {
    days_to_build = []
    timezone      = null
    branch_filter = null
    aks           = []
    sa_sftp       = []
  }

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

  validation {
    condition = alltrue(
      flatten([
        for s in var.schedule_configuration.aks : [
          split(",", s.system.nodes_on_stop)[0] >= 1,
          split(",", s.system.nodes_on_start)[0] >= 1
        ]
      ])
    )
    error_message = "System pool min nodes must not be lower than 1"
  }

  validation {
    condition = alltrue(
      flatten([
        for s in var.schedule_configuration.aks : [
          split(",", s.system.nodes_on_start)[0] < split(",", s.system.nodes_on_start)[1],
          split(",", s.user.nodes_on_start)[0] < split(",", s.user.nodes_on_start)[1],
        ]
      ])
    )
    error_message = "Nodes on start max value must be higher than min value"
  }
}
