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

resource "azuredevops_build_definition" "pipeline" {
  depends_on = [null_resource.this, module.secrets]

  project_id = var.project_id
  name       = var.name
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
    name         = "AZURE_TENANT_ID"
    secret_value = var.tenant_id
    is_secret    = true
  }

  variable {
    name         = "AZURE_SUBSCRIPTION_ID"
    secret_value = var.subscription_id
    is_secret    = true
  }

  variable {
    name         = "AZURE_CLIENT_ID"
    secret_value = jsondecode(module.secrets.values["azdo-sp-acme-challenge-${replace(var.dns_record_name, ".", "-")}-${replace(var.dns_zone_name, ".", "-")}"].value).appId
    is_secret    = true
  }

  variable {
    name         = "AZURE_CLIENT_SECRET"
    secret_value = jsondecode(module.secrets.values["azdo-sp-acme-challenge-${replace(var.dns_record_name, ".", "-")}-${replace(var.dns_zone_name, ".", "-")}"].value).password
    is_secret    = true
  }

  variable {
    name  = "AZURE_DNS_ZONE_RESOURCE_GROUP"
    value = var.dns_zone_resource_group
  }

  variable {
    name  = "AZURE_DNS_ZONE"
    value = var.dns_zone_name
  }

  variable {
    name  = "CSR_COMMON_NAME"
    value = "${var.dns_record_name}.${var.dns_zone_name}"
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
    subscription_id           = var.subscription_id
    subscription_name         = var.subscription_name
    credential_subcription    = var.credential_subcription
    credential_key_vault_name = var.credential_key_vault_name
    dns_record_name           = var.dns_record_name
    dns_zone_name             = var.dns_zone_name
    dns_zone_resource_group   = var.dns_zone_resource_group
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_create_for_rbac
  provisioner "local-exec" {
    command = <<EOT
      CURRENT_SUBSCRIPTION=$(az account list -o tsv --query "[?isDefault == \`true\`].{Name:name}")

      az account set --subscription "${self.triggers.subscription_name}"

      CREDENTIAL_VALUE=$(az ad sp create-for-rbac \
        --name "azdo-sp-acme-challenge-${replace(self.triggers.dns_record_name, ".", "-")}-${replace(self.triggers.dns_zone_name, ".", "-")}" \
        --role "DNS Zone Contributor" \
        --scope "/subscriptions/${self.triggers.subscription_id}/resourceGroups/${self.triggers.dns_zone_resource_group}/providers/Microsoft.Network/dnszones/${self.triggers.dns_zone_name}/TXT/_acme-challenge.${self.triggers.dns_record_name}")

      az keyvault secret set \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${replace(self.triggers.dns_record_name, ".", "-")}-${replace(self.triggers.dns_zone_name, ".", "-")}" \
        --value "$CREDENTIAL_VALUE"
      
      az account set --subscription "$CURRENT_SUBSCRIPTION"
    EOT
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_delete
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      CURRENT_SUBSCRIPTION=$(az account list -o tsv --query "[?isDefault == \`true\`].{Name:name}")

      SERVICE_PRINCIPAL_ID=$(az keyvault secret show \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${replace(self.triggers.dns_record_name, ".", "-")}-${replace(self.triggers.dns_zone_name, ".", "-")}" \
        -o tsv --query value | jq -r '.appId')

      az account set --subscription "${self.triggers.subscription_name}"
      az ad sp delete --id "$SERVICE_PRINCIPAL_ID"
      
      az keyvault secret delete \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${replace(self.triggers.dns_record_name, ".", "-")}-${replace(self.triggers.dns_zone_name, ".", "-")}"
      
      sleep 30

      az keyvault secret purge \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-acme-challenge-${replace(self.triggers.dns_record_name, ".", "-")}-${replace(self.triggers.dns_zone_name, ".", "-")}"

      az account set --subscription "$CURRENT_SUBSCRIPTION"
    EOT
  }
}

module "secrets" {
  depends_on = [null_resource.this]
  source     = "git::https://github.com/pagopa/azurerm.git//key_vault_secrets_query?ref=v1.0.11"

  resource_group = var.credential_key_vault_resource_group
  key_vault_name = var.credential_key_vault_name

  secrets = [
    "azdo-sp-acme-challenge-${replace(var.dns_record_name, ".", "-")}-${replace(var.dns_zone_name, ".", "-")}",
  ]
}
