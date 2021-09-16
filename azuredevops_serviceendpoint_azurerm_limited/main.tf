terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "= 0.1.4"
    }
    time = {
      version = "~> 0.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "=3.1.0"
    }
  }
}

resource "null_resource" "this" {
  # needs az cli > 2.0.81
  # see https://github.com/Azure/azure-cli/issues/12152

  triggers = {
    name                      = var.name
    subscription_name         = var.subscription_name
    credential_subcription    = var.credential_subcription
    credential_key_vault_name = var.credential_key_vault_name
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_create_for_rbac
  provisioner "local-exec" {
    command = <<EOT
      CURRENT_SUBSCRIPTION=$(az account list -o tsv --query "[?isDefault == \`true\`].{Name:name}")

      az account set --subscription "${self.triggers.subscription_name}"

      CREDENTIAL_VALUE=$(az ad sp create-for-rbac \
        --name "azdo-sp-${self.triggers.name}" \
        --skip-assignment true)
      
      az keyvault secret set \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-${self.triggers.name}" \
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
        --name "azdo-sp-${self.triggers.name}" \
        -o tsv --query value | jq -r '.appId')

      az account set --subscription "${self.triggers.subscription_name}"
      az ad sp delete --id "$SERVICE_PRINCIPAL_ID"
      
      az keyvault secret delete \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-${self.triggers.name}"
      
      sleep 30

      az keyvault secret purge \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-${self.triggers.name}"

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
    "azdo-sp-${var.name}",
  ]
}

# Azure DevOps service connection
resource "azuredevops_serviceendpoint_azurerm" "this" {
  depends_on = [null_resource.this, module.secrets]

  project_id                = var.project_id
  service_endpoint_name     = "${upper(var.name)}-SERVICE-CONN"
  description               = "${upper(var.name)} Service connection for TLS certificates"
  azurerm_subscription_name = var.subscription_name
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  credentials {
    serviceprincipalid  = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).appId
    serviceprincipalkey = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).password
  }
}
