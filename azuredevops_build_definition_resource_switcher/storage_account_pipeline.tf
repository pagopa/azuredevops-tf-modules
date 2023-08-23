locals {
  sa_config = tolist(flatten([
    for sa in var.schedule_configuration.sa_sftp : [
      {
        sa_name                = sa.sa_name
        action                 = "start"
        execution_time_hour    = split(":", sa.start_time)[0]
        execution_time_minutes = split(":", sa.start_time)[1]
      },
      {
        sa_name                = sa.sa_name
        action                 = "stop"
        execution_time_hour    = split(":", sa.stop_time)[0]
        execution_time_minutes = split(":", sa.stop_time)[1]
      }
    ]
  ]))
  service_connection_ids_sa_total_combinations_count = length(local.sa_config) * length(var.service_connection_ids_authorization)

}


resource "azuredevops_build_definition" "sa_pipeline" {

  count = length(local.sa_config)

  project_id      = var.project_id
  name            = "switcher-${local.sa_config[count.index].action}-${local.sa_config[count.index].sa_name}"
  path            = "\\${var.path}"
  agent_pool_name = var.agent_pool_name

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.repository.organization}/${var.repository.name}"
    branch_name           = var.repository.branch_name
    yml_path              = "${var.repository.pipelines_path}/sa-resource-switcher.yaml"
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

  ##################
  # common variables
  ##################
  variable {
    name           = "TF_ACTION"
    value          = local.sa_config[count.index].action
    is_secret      = false
    allow_override = false
  }

  variable {
    name           = "TF_TIMEOUT"
    value          = var.timeout
    is_secret      = false
    allow_override = false
  }

  ##################
  # aks specific variables
  ##################
  variable {
    name           = "TF_SA_NAME"
    value          = local.sa_config[count.index].sa_name
    is_secret      = false
    allow_override = false
  }





  schedules {
    days_to_build              = var.schedule_configuration.days_to_build
    schedule_only_with_changes = false
    start_hours                = local.sa_config[count.index].execution_time_hour
    start_minutes              = local.sa_config[count.index].execution_time_minutes
    time_zone                  = var.schedule_configuration.timezone
    branch_filter {
      include = var.schedule_configuration.branch_filter.include
      exclude = var.schedule_configuration.branch_filter.exclude
    }
  }

}

# This is to work around an issue with azuredevops_resource_authorization
# The service connection resource is not ready immediately
# so the recommendation is to wait 30 seconds until it's ready
# https://github.com/microsoft/terraform-provider-azuredevops/issues/266
resource "time_sleep" "sa_wait" {
  create_duration = "30s"
}

# github_service_connection_id serviceendpoint authorization
resource "azuredevops_resource_authorization" "sa_github_service_connection_authorization" {
  count      = length(local.aks_config)
  depends_on = [azuredevops_build_definition.aks_pipeline, time_sleep.sa_wait]

  project_id    = var.project_id
  resource_id   = var.github_service_connection_id
  definition_id = azuredevops_build_definition.aks_pipeline[count.index].id

  authorized = true
  type       = "endpoint"
}


##############################################################################################################################
#     why these formulas:
#     assume that:
#     - we have 2 sa: a and b -> we generate 2 pipelines for each sa: on and off (4 total in this example)
#     - we have 3 service connection ids: x, y, z
#
#     these are the combinations of pipelines (aON, aOFF, bON, bOFF) and connection ids that we need to handle
#             foreach count.index   |   index we need to use to get the pipeline   |   index we need to use to get the service connection id
#     a-ON-x	            0                             0	                                                      0
#     a-ON-y	            1                             0	                                                      1
#     a-ON-z	            2                             0	                                                      2
#     a-OFF-x	            3                             1	                                                      0
#     a-OFF-y	            4                             1	                                                      1
#     a-OFF-z	            5                             1	                                                      2
#     b-ON-x	            6                             2	                                                      0
#     b-ON-y	            7                             2	                                                      1
#     b-ON-z	            8                             2	                                                      2
#     b-OFF-x	            9	                            3	                                                      0
#     b-OFF-y	            10                            3	                                                      1
#     b-OFF-z	            11                            3	                                                      2
#     ------------------------------------------------------------------------------------------------------------------------------------
#                     count.index        floor(count.index/ number of service connection ids)         count.index % number of service connection ids
##############################################################################################################################
# others service_connection_ids serviceendpoint authorization
resource "azuredevops_resource_authorization" "sa_service_connection_ids_authorization" {
  depends_on = [azuredevops_build_definition.aks_pipeline, time_sleep.sa_wait]
  count      = local.service_connection_ids_sa_total_combinations_count

  project_id    = var.project_id
  resource_id   = var.service_connection_ids_authorization[count.index % length(var.service_connection_ids_authorization)]
  definition_id = azuredevops_build_definition.aks_pipeline[floor(count.index / length(var.service_connection_ids_authorization))].id

  authorized = true
  type       = "endpoint"
}

