terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "= 0.1.4"
    }
    time = {
      version = "~> 0.6.0"
    }
  }
}

locals {
  csr_common_name = trim("${var.dns_record_name}.${var.dns_zone_name}", ".")
  secret_name     = replace(trim("${var.dns_record_name}.${var.dns_zone_name}", "."), ".", "-")
}

resource "azuredevops_build_definition" "pipeline" {
  depends_on = [null_resource.this, module.secrets]

  project_id = var.project_id
  name       = trim(var.name, ".")
  path       = "\\${var.path}"

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
    name           = "LE_AZURE_CLIENT_ID"
    secret_value   = jsondecode(module.secrets.values["azdo-sp-acme-challenge-${local.secret_name}"].value).appId
    is_secret      = true
    allow_override = false
  }

  variable {
    name           = "LE_AZURE_CLIENT_SECRET"
    secret_value   = jsondecode(module.secrets.values["azdo-sp-acme-challenge-${local.secret_name}"].value).password
    is_secret      = true
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

resource "null_resource" "this" {
  # needs az cli > 2.0.81
  # see https://github.com/Azure/azure-cli/issues/12152

  triggers = {
    renew_token               = var.renew_token
    subscription_id           = var.subscription_id
    subscription_name         = var.subscription_name
    credential_subcription    = var.credential_subcription
    credential_key_vault_name = var.credential_key_vault_name
    dns_record_name           = var.dns_record_name
    dns_zone_name             = var.dns_zone_name
    name                      = local.secret_name
    dns_zone_resource_group   = var.dns_zone_resource_group
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_create_for_rbac
  provisioner "local-exec" {
    command = <<EOT
      CREDENTIAL_VALUE=$(az ad sp create-for-rbac \
        --name "azdo-sp-acme-challenge-${self.triggers.name}" \
        --role "DNS Zone Contributor" \
        --scope "/subscriptions/${self.triggers.subscription_id}/resourceGroups/${self.triggers.dns_zone_resource_group}/providers/Microsoft.Network/dnszones/${self.triggers.dns_zone_name}/TXT/${trim("_acme-challenge.${self.triggers.dns_record_name}", ".")}" \
        -o json)

      az keyvault secret set \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${self.triggers.name}" \
        --value "$CREDENTIAL_VALUE"
    EOT
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_delete
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      SERVICE_PRINCIPAL_ID=$(az keyvault secret show \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${self.triggers.name}" \
        -o tsv --query value | jq -r '.appId')

      az ad sp delete --id "$SERVICE_PRINCIPAL_ID"
      
      az keyvault secret delete \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${self.triggers.name}"
      
      sleep 30

      az keyvault secret purge \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${self.triggers.name}"
      
      sleep 30
    EOT
  }
}

module "secrets" {
  depends_on = [null_resource.this]
  source     = "git::https://github.com/pagopa/azurerm.git//key_vault_secrets_query?ref=v1.0.11"

  resource_group = var.credential_key_vault_resource_group
  key_vault_name = var.credential_key_vault_name

  secrets = [
    "azdo-sp-acme-challenge-${local.secret_name}",
    "le-private-key-json",
    "le-regr-json",
  ]
}
