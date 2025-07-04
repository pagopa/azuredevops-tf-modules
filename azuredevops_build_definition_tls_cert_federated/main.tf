locals {
  csr_common_name = trim("${var.dns_record_name}.${var.dns_zone_name}", ".")
  secret_name     = replace(trim("${var.dns_record_name}.${var.dns_zone_name}", "."), ".", "-")
}

module "secrets" {
  source         = "git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query?ref=v8.21.0"
  resource_group = var.credential_key_vault_resource_group
  key_vault_name = var.credential_key_vault_name

  secrets = [
    "le-private-key-json",
    "le-regr-json",
  ]
}


#
# Pipeline
#
resource "azuredevops_build_definition" "pipeline" {
  depends_on = [module.secrets]

  project_id      = var.project_id
  name            = trimprefix("${var.dns_record_name}.${var.dns_zone_name}", ".")
  path            = "\\${var.path}"
  agent_pool_name = var.agent_pool_name

  repository {
    repo_type             = var.repository_repo_type
    repo_id               = "${var.repository.organization}/${var.repository.name}"
    branch_name           = var.repository.branch_name
    yml_path              = "azure-pipelines-federated.yaml"
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

  variable {
    name           = "LE_AZURE_TENANT_ID"
    secret_value   = var.tenant_id
    is_secret      = true
    allow_override = false
  }

  variable {
    name           = "LE_AZURE_SUBSCRIPTION_ID"
    secret_value   = var.subscription_id
    is_secret      = true
    allow_override = false
  }

  variable {
    name           = "LE_SERVICE_CONNECTION"
    value          = module.azuredevops_serviceendpoint_federated.service_endpoint_name
    allow_override = false
  }

  variable {
    name           = "LE_AZURE_IDENTITY_TYPE"
    value          = "MANAGED_IDENTITY"
    allow_override = false
  }

  variable {
    name           = "AZURE_DNS_ZONE_RESOURCE_GROUP"
    value          = var.dns_zone_resource_group
    allow_override = false
  }

  variable {
    name           = "AZURE_DNS_ZONE"
    value          = var.dns_zone_name
    allow_override = false
  }

  variable {
    name           = "CSR_COMMON_NAME"
    value          = local.csr_common_name
    allow_override = false
  }

  variable {
    name           = "LE_PRIVATE_KEY_JSON"
    secret_value   = module.secrets.values["le-private-key-json"].value
    is_secret      = true
    allow_override = false
  }

  variable {
    name           = "LE_REGR_JSON"
    secret_value   = module.secrets.values["le-regr-json"].value
    is_secret      = true
    allow_override = false
  }

  variable {
    name           = "KEY_VAULT_CERT_NAME"
    value          = local.secret_name
    allow_override = false
  }

  variable {
    name           = "KEY_VAULT_NAME"
    value          = var.credential_key_vault_name
    allow_override = false
  }

  variable {
    name           = "CERT_NAME_EXPIRE_SECONDS"
    value          = var.cert_name_expire_seconds
    allow_override = false
  }

  dynamic "schedules" {
    for_each = var.schedules != null ? [var.schedules] : []
    iterator = s
    content {
      days_to_build              = s.value.days_to_build
      schedule_only_with_changes = s.value.schedule_only_with_changes
      start_hours                = s.value.start_hours
      start_minutes              = s.value.start_minutes
      time_zone                  = s.value.time_zone
      branch_filter {
        include = s.value.branch_filter.include
        exclude = s.value.branch_filter.exclude
      }
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
resource "azuredevops_pipeline_authorization" "github_service_connection_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]

  project_id  = var.project_id
  resource_id = var.github_service_connection_id
  pipeline_id = azuredevops_build_definition.pipeline.id
  type        = "endpoint"
}

# outhorize other service connection usage from the pipeline.
# this is typically used for authorizing the service connection
# for accessing the certificate in key vault.
# these service connections are passed to this module as vars.
resource "azuredevops_pipeline_authorization" "service_connection_ids_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]
  count      = var.service_connection_ids_authorization == null ? 0 : length(var.service_connection_ids_authorization)

  project_id  = var.project_id
  resource_id = var.service_connection_ids_authorization[count.index]
  pipeline_id = azuredevops_build_definition.pipeline.id
  type        = "endpoint"
}


# DNS Managed identity + Service connection for pipeline
# this two object are mandatory for permission in DNS and allow pipeline to use
# service connection id and not more service principal id and secret
#

# service endpoint for federated authorizion, used for accessing dns txt record of acme challenge

# federated service endpoint for accessing dns txt record of acme challenge.
# the managed identity related to this service endpoint will be able ONLY to
# access that specific txt record.
# this means that there will be at least two different service connections,
# with related managed identities in azure: one for accessing the txt record,
# needed for acme, and one for accessing the certificate in key vault, needed
# for checking certicate expiration and for updating with the new certificate
# provided by let's encrypt.
module "azuredevops_serviceendpoint_federated" {
  source = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_serviceendpoint_federated?ref=v9.0.0"

  project_id          = var.project_id
  name                = "azdo-acme-challenge-${local.secret_name}"
  tenant_id           = var.tenant_id
  subscription_name   = var.subscription_name
  subscription_id     = var.subscription_id
  location            = var.location
  resource_group_name = var.managed_identity_resource_group_name
}

# authorize the service endpoint for accessing txt record to be used by the pipeline
resource "azuredevops_pipeline_authorization" "service_connection_le_authorization" {
  depends_on = [time_sleep.wait]

  project_id  = var.project_id
  resource_id = module.azuredevops_serviceendpoint_federated.service_endpoint_id
  pipeline_id = azuredevops_build_definition.pipeline.id
  type        = "endpoint"
}

# authorize the service endpoint created to read/write access to txt record
resource "azurerm_role_assignment" "managed_identity_default_role_assignment" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.dns_zone_resource_group}/providers/Microsoft.Network/dnszones/${var.dns_zone_name}/TXT/${trim("_acme-challenge.${var.dns_record_name}", ".")}"
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.azuredevops_serviceendpoint_federated.identity_principal_id
}


#
# Pipeline Cert Diff
#

data "azurerm_application_insights" "this" {
  count = var.cert_diff_variables.enabled ? 1 : 0

  name                = var.cert_diff_variables.app_insights_name
  resource_group_name = var.cert_diff_variables.app_insights_rg
}

resource "azuredevops_build_definition" "pipeline_cert_diff" {
  depends_on = [azuredevops_build_definition.pipeline]
  count      = var.cert_diff_variables.enabled ? 1 : 0

  project_id      = var.project_id
  name            = "${trimprefix("${var.dns_record_name}.${var.dns_zone_name}", ".")}-[Cert-Diff]"
  path            = "\\${var.path}"
  agent_pool_name = var.agent_pool_name

  repository {
    repo_type             = var.repository_repo_type
    repo_id               = "${var.repository.organization}/${var.repository.name}"
    branch_name           = var.repository.branch_name
    yml_path              = "azure-pipeline-cert-diff.yaml"
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

  variable {
    name           = "KEY_VAULT_CERT_NAME"
    value          = local.secret_name
    allow_override = false
  }

  variable {
    name           = "KEY_VAULT_CERT_NAME_STABLE"
    value          = "${local.secret_name}-stable"
    allow_override = false
  }

  variable {
    name           = "KEY_VAULT_NAME"
    value          = var.credential_key_vault_name
    allow_override = false
  }

  variable {
    name           = "CERT_NAME_EXPIRE_SECONDS"
    value          = var.cert_name_expire_seconds
    allow_override = false
  }

  variable {
    name           = "CERT_DIFF_VERSION"
    value          = var.cert_diff_variables.cert_diff_version
    allow_override = false
  }

  variable {
    name           = "APP_INSIGHT_CONNECTION_STRING"
    secret_value   = data.azurerm_application_insights.this[0].connection_string
    is_secret      = true
    allow_override = false
  }

  build_completion_trigger {
    build_definition_id = azuredevops_build_definition.pipeline.id
    branch_filter {
      include = [var.repository.branch_name]
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "cert_diff_alert" {
  count = var.cert_diff_variables.alert_enabled ? 1 : 0

  name                = "${trimprefix("${var.dns_record_name}.${var.dns_zone_name}", "-")} cert diff alert"
  resource_group_name = data.azurerm_application_insights.this[0].resource_group_name
  location            = data.azurerm_application_insights.this[0].location
  description         = "Alert if ${trimprefix("${var.dns_record_name}.${var.dns_zone_name}", "-")}-[Cert-Diff] pipeline status is missing or failed in the last 8 days"
  enabled             = true
  severity            = 2
  frequency           = 1440 # 24 hours
  time_window         = 2880

  data_source_id = data.azurerm_application_insights.this[0].id

  action {
    action_group = var.cert_diff_variables.actions_group
  }

  query = <<-QUERY
    let expectedTests = availabilityResults
    | where name contains "${trimprefix("${var.dns_record_name}.${var.dns_zone_name}", ".")}-[Cert-Diff]"
    | where timestamp > ago(${var.cert_name_expire_seconds}s)
    | summarize by name;

    let recentResults = availabilityResults
    | where name contains "${trimprefix("${var.dns_record_name}.${var.dns_zone_name}", ".")}-[Cert-Diff]"
    | where timestamp > ago(7d)
    | summarize hasFailure = any(success == false), hasAny = count() > 0 by name;

    expectedTests
    | join kind=leftouter recentResults on name
    | extend status = iff(isnull(hasAny), "Missing", iff(hasFailure, "Failed", "OK"))
    | where status in ("Missing", "Failed")
    | project name, status
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}
