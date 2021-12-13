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

variable "name" {
  type        = string
  description = "(Required) Pipeline name equals to domain name"
}

variable "path" {
  type        = string
  description = "(Required) Pipeline path on Azure DevOps"
}

variable "agent_pool_name" {
  type        = string
  default     = "Hosted Ubuntu 1604"
  description = "The agent pool that should execute the build"
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
