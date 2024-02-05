resource "azuredevops_build_definition" "pipeline" {
  project_id      = var.project_id
  name            = var.pipeline_name
  path            = "\\${var.path}"
  agent_pool_name = var.agent_pool_name

  repository {
    repo_type             = var.repository_repo_type
    repo_id               = "${var.repository.organization}/${var.repository.name}"
    branch_name           = var.repository.branch_name
    yml_path              = "${var.repository.pipelines_path}/${var.pipeline_yml_filename}"
    service_connection_id = var.github_service_connection_id
  }

  # ci_trigger {
  #   use_yaml = var.ci_trigger_use_yaml == false ? null : true
  # }

  dynamic "ci_trigger" {
    for_each = var.ci_trigger_use_yaml == false ? [] : ["dummy"]

    content {
      use_yaml = var.ci_trigger_use_yaml
    }
  }

  dynamic "pull_request_trigger" {

    for_each = ["dummy"]

    content {
      use_yaml       = var.pull_request_trigger_use_yaml == false ? null : true
      initial_branch = var.repository.branch_name

      forks {
        enabled       = false
        share_secrets = false
      }

      dynamic "override" {
        for_each = var.pull_request_trigger_use_yaml == true ? [] : ["dummy"]

        content {
          auto_cancel = var.pull_request_trigger_auto_cancel
          branch_filter {
            include = [var.repository.branch_name]
          }
          path_filter {
            exclude = []
            include = []
          }
        }
      }
    }
  }

  dynamic "variable" {
    for_each = var.variables
    iterator = variable

    content {
      name           = upper(variable.key)
      value          = variable.value
      allow_override = false
    }
  }

  dynamic "variable" {
    for_each = var.variables_secret
    iterator = variable_secret

    content {
      name           = upper(variable_secret.key)
      secret_value   = variable_secret.value
      is_secret      = true
      allow_override = false
    }
  }

  lifecycle {
    ignore_changes = [
      pull_request_trigger.0.override.0.auto_cancel,
    ]
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
resource "azuredevops_pipeline_authorization" "github_service_connection_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]

  project_id  = var.project_id
  resource_id = var.github_service_connection_id
  pipeline_id = azuredevops_build_definition.pipeline.id
  type        = "endpoint"
}

# others service_connection_ids serviceendpoint authorization
resource "azuredevops_pipeline_authorization" "service_connection_ids_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]
  count      = var.service_connection_ids_authorization == null ? 0 : length(var.service_connection_ids_authorization)

  project_id  = var.project_id
  resource_id = var.service_connection_ids_authorization[count.index]
  pipeline_id = azuredevops_build_definition.pipeline.id
  type        = "endpoint"
}
