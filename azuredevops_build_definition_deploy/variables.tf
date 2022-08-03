variable "project_id" {
  type        = string
  description = "(Required) Azure DevOps project ID"
}

variable "pipeline_name" {
  type        = string
  description = "Name of the pipeline. If null it will be the repository name."
  default     = null
}


variable "repository" {
  type = object({
    organization    = string # organization name (e.g. pagopaspa)
    name            = string # repository name inside the organizzation
    branch_name     = string
    pipelines_path  = string # path where i can find the pipelines yaml
    yml_prefix_name = string # prefix for yaml pipeline
  })
  description = "(Required) GitHub repository attributes"
}

variable "path" {
  type        = string
  description = "(Required) Pipeline path on Azure DevOps"
}

variable "ci_trigger_use_yaml" {
  type        = bool
  description = "(Optional) Use the azure-pipeline file for the build configuration. Defaults to false."
  default     = false
}

variable "pull_request_trigger_use_yaml" {
  type        = bool
  description = "(Optional) Use the azure-pipeline file for the build configuration. Defaults to false."
  default     = false
}

# todo not works
# variable "ci_trigger" {
#   type = object({
#     branch_filter = object({
#       exclude = list(string)
#       include = list(string)
#     })
#     path_filter = object({
#       exclude = list(string)
#       include = list(string)
#     })
#   })
#   description = "(Optional) CI trigger policy"
#   default     = null
# }

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

variable "agent_pool_name" {
  type        = string
  default     = "Azure Pipelines"
  description = "The agent pool that should execute the build"
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
  default     = null
  description = "Allow to setup schedules trigger in azure devops. Usign that the schedules used in the yaml will be disabled"
}
