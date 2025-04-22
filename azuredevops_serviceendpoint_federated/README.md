# azuredevops_serviceendpoint_federated

This module allow the creation of a service connection (azurerm type) with name: `azdo-sp-****`.
Using a Service Principal, and store the credentials into a Key Vault.

> 🏁 This connection can be used to manage from azure devops, azure resources inside subscription

## Architecture

![This is an image](./docs/module-arch.drawio.png)

## How to use it

```json
module "LAB-TLS-CERT-SERVICE-CONN" {
  depends_on = [azuredevops_project.project]
  source     = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_serviceendpoint_azurerm_limited?ref=v2.0.4"
  providers = {
    azurerm = azurerm.lab
  }

  project_id        = azuredevops_project.project.id
  renew_token       = local.tlscert_renew_token
  name              = "${local.prefix}-d-tls-cert"
  tenant_id         = module.secrets.values["TENANTID"].value
  subscription_id   = module.secrets.values["LAB-SUBSCRIPTION-ID"].value
  subscription_name = var.lab_subscription_name

  credential_subcription              = var.lab_subscription_name
  credential_key_vault_name           = local.dev_key_vault_name
  credential_key_vault_resource_group = local.dev_key_vault_resource_group
}

locals {
    renew_token = "v1"
}
```

> Use **renew_token** to force module to recreate the resource, for example change the value to "v2"

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) | ~> 1.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.107 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuredevops"></a> [azuredevops](#provider\_azuredevops) | ~> 1.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.107 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuredevops_check_approval.this](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/check_approval) | resource |
| [azuredevops_serviceendpoint_azurerm.azurerm](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/serviceendpoint_azurerm) | resource |
| [azurerm_federated_identity_credential.federated_setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_role_assignment.managed_identity_default_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_resource_group.default_assignment_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_approver_ids"></a> [approver\_ids](#input\_approver\_ids) | (Optional) Credential IDs for approving the use of the service connection | `list(string)` | `[]` | no |
| <a name="input_check_approval_enabled"></a> [check\_approval\_enabled](#input\_check\_approval\_enabled) | (Optional) Flag to approve use of the service connection | `bool` | `false` | no |
| <a name="input_default_roleassignment_rg_prefix"></a> [default\_roleassignment\_rg\_prefix](#input\_default\_roleassignment\_rg\_prefix) | (Optional) Add a prefix to default\_roleassignment\_rg | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) Managed identity & Service connection name (if not defined `serviceendpoint_azurerm_name`) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group where the managed identity will be create | `string` | n/a | yes |
| <a name="input_serviceendpoint_azurerm_name"></a> [serviceendpoint\_azurerm\_name](#input\_serviceendpoint\_azurerm\_name) | (Optional) Service connection azurerm name | `string` | `""` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | (Required) Azure Subscription ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | (Required) Azure Subscription name related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Required) Azure Tenant ID related to tenant where create service principal | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_identity_app_name"></a> [identity\_app\_name](#output\_identity\_app\_name) | User Managed Identity name |
| <a name="output_identity_client_id"></a> [identity\_client\_id](#output\_identity\_client\_id) | The ID of the app associated with the Identity. |
| <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id) | The ID of the Service Principal object associated with the created Identity. |
| <a name="output_service_endpoint_id"></a> [service\_endpoint\_id](#output\_service\_endpoint\_id) | Service endpoint id |
| <a name="output_service_endpoint_name"></a> [service\_endpoint\_name](#output\_service\_endpoint\_name) | Service endpoint name |
| <a name="output_service_principal_object_id"></a> [service\_principal\_object\_id](#output\_service\_principal\_object\_id) | The ID of the Service Principal object associated with the created Identity. |
<!-- END_TF_DOCS -->
