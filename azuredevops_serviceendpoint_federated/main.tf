#
# Managed identity
#
resource "azurerm_user_assigned_identity" "identity" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "federated_setup" {
  parent_id           = azurerm_user_assigned_identity.identity.id
  name                = var.name
  resource_group_name = var.resource_group_name
  audience            = [local.default_audience_name]
  issuer              = azuredevops_serviceendpoint_azurerm.azurerm.workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.azurerm.workload_identity_federation_subject
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
resource "azuredevops_serviceendpoint_azurerm" "azurerm" {
  project_id                             = var.project_id
  service_endpoint_name                  = local.serviceendpoint_azurerm_name
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.identity.client_id
  }
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = var.subscription_name
}

#
# Approval
#

resource "azuredevops_check_approval" "this" {
  count = var.check_approval_enabled ? 1 : 0

  project_id           = var.project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.azurerm.id
  target_resource_type = "endpoint"

  requester_can_approve = true
  approvers             = var.approver_ids
  timeout               = 120
}
