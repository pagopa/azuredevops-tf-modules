terraform {
  required_version = ">= 0.14.5"
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.8"
    }
    time = {
      version = "~> 0.7.0"
    }
  }
}

resource "azuredevops_build_definition" "pipeline" {
  project_id      = var.project_id
  name            = var.name
  path            = "\\${var.path}"
  agent_pool_name = var.agent_pool_name

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.repository.organization}/${var.repository.name}"
    branch_name           = var.repository.branch_name
    yml_path              = "azure-pipelines.yml"
    service_connection_id = var.github_service_connection_id
  }

  dynamic "variable" {
    for_each = var.variables
    iterator = variable

    content {
      name           = variable.key
      value          = variable.value
      allow_override = false
    }
  }

  dynamic "variable" {
    for_each = var.variables_secret
    iterator = variable_secret

    content {
      name           = variable_secret.key
      secret_value   = variable_secret.value
      is_secret      = true
      allow_override = false
    }
  }
}

# This is to work around an issue with azuredevops_resource_authorization
# The service connection resource is not ready immediately
# so the recommendation is to wait 30 seconds until it's ready
# https://github.com/microsoft/terraform-provider-azuredevops/issues/266
resource "time_sleep" "wait" {
  create_duration = "30s"
}

# github_service_connection_id serviceendpoint authorization
resource "azuredevops_resource_authorization" "github_service_connection_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]

  project_id    = var.project_id
  resource_id   = var.github_service_connection_id
  definition_id = azuredevops_build_definition.pipeline.id
  authorized    = true
  type          = "endpoint"
}

# others service_connection_ids serviceendpoint authorization
resource "azuredevops_resource_authorization" "service_connection_ids_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]
  count      = var.service_connection_ids_authorization == null ? 0 : length(var.service_connection_ids_authorization)

  project_id    = var.project_id
  resource_id   = var.service_connection_ids_authorization[count.index]
  definition_id = azuredevops_build_definition.pipeline.id
  authorized    = true
  type          = "endpoint"
}