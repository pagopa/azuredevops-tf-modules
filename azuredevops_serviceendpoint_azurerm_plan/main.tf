data "azuread_group" "group_directory_reader_permissions" {
  display_name = var.iac_aad_group_name
}

data "azurerm_key_vault" "kv" {
  name                = var.credential_key_vault_name
  resource_group_name = var.credential_key_vault_resource_group
}

data "azurerm_subscription" "this" {
}

data "azurerm_resource_group" "this" {
  name = "default-roleassignment-rg"
}

#
# Create App
#
resource "azuread_application" "plan_app" {
  display_name = local.app_name
}

resource "time_rotating" "credential_password_days" {
  rotation_days = var.password_time_rotation_days
}

resource "azuread_application_password" "plan_app" {
  service_principal_id = azuread_application.plan_app.object_id
  rotate_when_changed = {
    rotation = time_rotating.credential_password_days.id
  }
}

## SP
resource "azuread_service_principal" "plan_app" {
  application_id = azuread_application.plan_app.application_id
}

#
# KeyVault
#
resource "azurerm_key_vault_secret" "credentials_password_value" {
  name         = local.app_name
  value        = azuread_service_principal_password.plan_app.value
  key_vault_id = data.azurerm_key_vault.kv.id
}

#
# Roles
#

# assign SP to group with Directory Reader
resource "azuread_group_member" "add_plan_app_to_directory_readers_group" {
  group_object_id  = data.azuread_group.group_directory_reader_permissions.id
  member_object_id = azuread_service_principal.plan_app.object_id
}

# assign SP to default resource group to allow to be linked to subscription
resource "azurerm_role_assignment" "default_resource_group_reader" {
  scope                = data.azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.plan_app.object_id
}

resource "azurerm_role_assignment" "pagopa_iac_reader" {
  scope                = data.azurerm_subscription.this.id
  role_definition_name = var.custom_role_name
  principal_id         = azuread_service_principal.plan_app.object_id
}

resource "azurerm_role_assignment" "plan_app_subscription" {
  for_each             = toset(local.plan_app_roles.permissions)

  scope                = data.azurerm_subscription.this.id
  role_definition_name = each.key
  principal_id         = azuread_service_principal.plan_app.object_id
}



# resource "azurerm_role_assignment" "plan_app_tfstate_inf" {
#   scope                = data.azurerm_storage_account.tfstate_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azuread_service_principal.plan_app.object_id
# }

# resource "null_resource" "this" {
#   # needs az cli > 2.0.81
#   # see https://github.com/Azure/azure-cli/issues/12152

#   triggers = {
#     renew_token                      = var.renew_token
#     name                             = var.name_suffix
#     subscription_name                = var.subscription_name
#     subscription_id                  = data.azurerm_subscription.this.id
#     credential_subcription           = var.credential_subcription
#     credential_key_vault_name        = var.credential_key_vault_name
#     default_roleassignment_rg_prefix = var.default_roleassignment_rg_prefix
#   }

#   # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_create_for_rbac
#   provisioner "local-exec" {
#     command = <<EOT
#       SP_CREDENTIAL_VALUES=$(az ad sp create-for-rbac \
#         --name "azdo-sp-${self.triggers.name}" \
#         --role "Reader" \
#         --scope "/subscriptions/${self.triggers.subscription_id}/resourceGroups/${self.triggers.default_roleassignment_rg_prefix}default-roleassignment-rg" \
#         -o json)

#       az keyvault secret set \
#         --subscription "${self.triggers.credential_subcription}" \
#         --vault-name "${self.triggers.credential_key_vault_name}" \
#         --name "azdo-sp-${self.triggers.name}" \
#         --value "$SP_CREDENTIAL_VALUES"
#     EOT
#   }

#   # https://docs.microsoft.com/it-it/cli/azure/ad/sp?view=azure-cli-latest#az_ad_sp_delete
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<EOT
#       SERVICE_PRINCIPAL_ID=$(az keyvault secret show \
#         --subscription "${self.triggers.credential_subcription}" \
#         --vault-name "${self.triggers.credential_key_vault_name}" \
#         --name "azdo-sp-${self.triggers.name}" \
#         -o tsv --query value | jq -r '.appId')

#       az ad sp delete --id "$SERVICE_PRINCIPAL_ID"

#       az keyvault secret set \
#         --subscription "${self.triggers.credential_subcription}" \
#         --vault-name "${self.triggers.credential_key_vault_name}" \
#         --name "azdo-sp-${self.triggers.name}" \
#         --value "DELETEME" \
#         --disabled true \
#         --description "DELETEME"
#     EOT
#   }
# }

module "secrets" {
  depends_on = [azurerm_key_vault_secret.credentials_password_value]
  source     = "git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query?ref=v6.15.2"

  resource_group = var.credential_key_vault_resource_group
  key_vault_name = var.credential_key_vault_name

  secrets = [
    azurerm_key_vault_secret.credentials_password_value.name,
  ]
}

# Azure DevOps service connection
resource "azuredevops_serviceendpoint_azurerm" "this" {
  depends_on = [module.secrets]

  project_id            = var.project_id
  service_endpoint_name = "${upper(var.name_suffix)}-PLAN-SERVICE-CONN"
  description           = "${upper(var.name_suffix)} Azure Service connection for PLAN"

  # azurerm_subscription_name = var.subscription_name
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.this.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.this.display_name

  credentials {
    serviceprincipalid  = azuread_service_principal.plan_app.object_id
    serviceprincipalkey = azuread_service_principal_password.plan_app.value
  }
}

# This is to work around an issue with azuredevops_resource_authorization
# The service connection resource is not ready immediately
# so the recommendation is to wait 30 seconds until it's ready
resource "time_sleep" "wait" {
  create_duration = "60s"
}

data "azuread_service_principal" "this" {
  depends_on   = [time_sleep.wait]
  display_name = azuread_service_principal.plan_app.display_name
}
