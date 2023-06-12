# This is to work around an issue with azuredevops_resource_authorization
# The service connection resource is not ready immediately
# so the recommendation is to wait 30 seconds until it's ready
resource "time_sleep" "wait" {
  create_duration = "60s"
}

resource "null_resource" "this" {
  # needs az cli > 2.0.81
  # see https://github.com/Azure/azure-cli/issues/12152

  triggers = {
    renew_token                      = var.renew_token
    name                             = var.name
    subscription_name                = var.subscription_name
    subscription_id                  = var.subscription_id
    credential_subcription           = var.credential_subcription
    credential_key_vault_name        = var.credential_key_vault_name
    default_roleassignment_rg_prefix = var.default_roleassignment_rg_prefix
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_create_for_rbac
  provisioner "local-exec" {
    command = <<EOT
      SP_CREDENTIAL_VALUES=$(az ad sp create-for-rbac \
        --name "azdo-sp-${self.triggers.name}" \
        --role "Reader" \
        --scope "/subscriptions/${self.triggers.subscription_id}/resourceGroups/${self.triggers.default_roleassignment_rg_prefix}default-roleassignment-rg" \
        -o json)

      az keyvault secret set \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-${self.triggers.name}" \
        --value "$SP_CREDENTIAL_VALUES"
    EOT
  }

  # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_delete
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      SERVICE_PRINCIPAL_ID=$(az keyvault secret show \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-${self.triggers.name}" \
        -o tsv --query value | jq -r '.appId')

      az ad sp delete --id "$SERVICE_PRINCIPAL_ID"

      az keyvault secret set \
        --subscription "${self.triggers.credential_subcription}" \
        --vault-name "${self.triggers.credential_key_vault_name}" \
        --name "azdo-sp-${self.triggers.name}" \
        --value "DELETEME" \
        --disabled true \
        --description "DELETEME"
    EOT
  }
}

module "secrets" {
  depends_on = [null_resource.this]
  source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query?ref=v6.15.2"

  resource_group = var.credential_key_vault_resource_group
  key_vault_name = var.credential_key_vault_name

  secrets = [
    "azdo-sp-${var.name}",
  ]
}

# Azure DevOps service connection
resource "azuredevops_serviceendpoint_azurerm" "this" {
  depends_on = [null_resource.this, module.secrets]

  project_id            = var.project_id
  service_endpoint_name = "${upper(var.name)}-SERVICE-CONN"
  description           = "${upper(var.name)} Service connection for TLS certificates"

  azurerm_subscription_name = var.subscription_name
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id

  credentials {
    serviceprincipalid  = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).appId
    serviceprincipalkey = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).password
  }
}

data "azuread_service_principal" "this" {
  depends_on   = [time_sleep.wait]
  display_name = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).displayName
}
