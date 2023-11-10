locals {
  csr_common_name = trim("${var.dns_record_name}.${var.dns_zone_name}", ".")
  secret_name     = replace(trim("${var.dns_record_name}.${var.dns_zone_name}", "."), ".", "-")
}

resource "azuredevops_build_definition" "pipeline" {
  depends_on = [module.secrets]

  project_id      = var.project_id
  name            = trim(var.name, ".")
  path            = "\\${var.path}"
  agent_pool_name = var.agent_pool_name

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.repository.organization}/${var.repository.name}"
    branch_name           = var.repository.branch_name
    yml_path              = "azure-pipelines.yaml"
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
    name           = "KEY_VAULT_CERT_NAME"
    value          = local.secret_name
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
# TODO tom: this should be fixed by https://github.com/microsoft/terraform-provider-azuredevops/pull/475/commits/742006154cd92b3177298a00adf61f9d250e0924 ??
resource "time_sleep" "wait" {
  create_duration = "30s"
}

# github_service_connection_id serviceendpoint authorization
resource "azuredevops_resource_authorization" "github_service_connection_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]

  project_id    = var.project_id
  resource_id   = var.github_service_connection_id
  definition_id = azuredevops_build_definition.pipeline.id

  authorized = true
  type       = "endpoint"
}

# others service_connection_ids serviceendpoint authorization
resource "azuredevops_resource_authorization" "service_connection_ids_authorization" {
  depends_on = [azuredevops_build_definition.pipeline, time_sleep.wait]
  count      = var.service_connection_ids_authorization == null ? 0 : length(var.service_connection_ids_authorization)

  project_id    = var.project_id
  resource_id   = var.service_connection_ids_authorization[count.index]
  definition_id = azuredevops_build_definition.pipeline.id

  authorized = true
  type       = "endpoint"
}

# service endpoint for federated authorizion, used for accessing dns txt record of acme challenge
module "azuredevops_serviceendpoint_federated" {
  source = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_serviceendpoint_federated?ref=v4.0.0"

  project_id          = var.project_id
  name                = "azdo-acme-challenge-${local.secret_name}"
  tenant_id           = var.tenant_id
  subscription_name   = var.subscription_name
  subscription_id     = var.subscription_id
  location            = var.location
  resource_group_name = var.dns_zone_resource_group
}

# authorize the service endpoint created to read/write access to txt record
resource "azurerm_role_assignment" "managed_identity_default_role_assignment" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.dns_zone_resource_group}/providers/Microsoft.Network/dnszones/${var.dns_zone_name}/TXT/${trim("_acme-challenge.${var.dns_record_name}", ".")}"
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.azuredevops_serviceendpoint_federated.identity_principal_id
}

module "secrets" {
  source         = "git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query?ref=v6.15.2"
  resource_group = var.credential_key_vault_resource_group
  key_vault_name = var.credential_key_vault_name

  secrets = [
    "le-private-key-json",
    "le-regr-json",
  ]
}
