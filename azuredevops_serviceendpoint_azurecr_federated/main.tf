#
# Managed identity
#
resource "azurerm_user_assigned_identity" "identity" {
  location            = var.location
  name                = var.serviceendpoint_azurecr_name_prefix
  resource_group_name = var.resource_group_name
}

# add role assignment to default roleassignment rg:
# the managed identity needs at least reader on one rg (or the whole subscription)

data "azurerm_resource_group" "default_assignment_rg" {
  name = "${var.default_roleassignment_rg_prefix}default-roleassignment-rg"
}

resource "azurerm_role_assignment" "managed_identity_default_role_assignment" {
  scope                = data.azurerm_resource_group.default_assignment_rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

#
# Service Endpoint - AZDO
#
resource "azuredevops_serviceendpoint_azurecr" "container_registry" {
  project_id                             = var.project_id
  resource_group                         = var.azurecr_resource_group_name
  service_endpoint_name                  = local.serviceendpoint_azurerm_name
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurecr_spn_tenantid                   = var.tenant_id
  azurecr_name                           = var.azurecr_name
  azurecr_subscription_id                = var.subscription_id
  azurecr_subscription_name              = var.subscription_name
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.identity.client_id
  }
}

resource "azurerm_federated_identity_credential" "federated_setup" {
  parent_id           = azurerm_user_assigned_identity.identity.id
  name                = var.serviceendpoint_azurecr_name_prefix
  resource_group_name = var.resource_group_name
  audience            = [local.default_audience_name]
  issuer              = azuredevops_serviceendpoint_azurecr.container_registry.workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurecr.container_registry.workload_identity_federation_subject
}
