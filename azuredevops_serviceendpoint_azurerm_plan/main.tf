data "azurerm_key_vault" "kv" {
  name                = var.credential_key_vault_name
  resource_group_name = var.credential_key_vault_resource_group
}

data "azurerm_subscription" "this" {
}

data "azurerm_resource_group" "this" {
  name = var.default_resource_group_name
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
  application_object_id = azuread_application.plan_app.object_id
  rotate_when_changed = {
    rotation = time_rotating.credential_password_days.id
    renew    = var.renew_token
  }
}

## SP
resource "azuread_service_principal" "sp_plan" {
  application_id = azuread_application.plan_app.application_id
}

#
# KeyVault
#
resource "azurerm_key_vault_secret" "credentials_password_value" {
  name         = local.app_name
  value        = azuread_application_password.plan_app.value
  key_vault_id = data.azurerm_key_vault.kv.id
}

#
# Roles
#

# assign SP to default resource group to allow to be linked to subscription
resource "azurerm_role_assignment" "default_resource_group_reader" {
  scope                = data.azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.sp_plan.object_id
}

resource "azurerm_role_assignment" "plan_app_subscription" {
  for_each = toset(local.plan_app_roles.permissions)

  scope                = data.azurerm_subscription.this.id
  role_definition_name = each.key
  principal_id         = azuread_service_principal.sp_plan.object_id
}

module "secrets" {
  depends_on = [azurerm_key_vault_secret.credentials_password_value]
  source     = "git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query?ref=v7.48.0"

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
    serviceprincipalid  = azuread_service_principal.sp_plan.application_id
    serviceprincipalkey = azuread_application_password.plan_app.value
  }
}
