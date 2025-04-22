# azuredevops_serviceendpoint_azurecr_federated

## Architecture

![This is an image](./docs/module-arch.drawio.png)

## How to use it

```hcl
module "dev_azurecr_service_conn" {
  source = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_serviceendpoint_azurecr_federated?ref=azurecr-workload-identity"
  providers = {
    azurerm = azurerm.dev
  }

  project_id = local.devops_project_id
  # #tfsec:ignore:general-secrets-no-plaintext-exposure
  serviceendpoint_azurecr_name_prefix = "${local.dev_docker_registry_name}-docker"

  tenant_id         = data.azurerm_client_config.current.tenant_id
  subscription_id   = data.azurerm_subscriptions.dev.subscriptions[0].subscription_id
  subscription_name = data.azurerm_subscriptions.dev.subscriptions[0].display_name

  location            = local.location_service_conn
  resource_group_name = local.dev_identity_rg_name

  azurecr_name = local.dev_docker_registry_name
  azurecr_resource_group_name = local.dev_docker_registry_rg_name
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) | >= 1.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.107 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuredevops"></a> [azuredevops](#provider\_azuredevops) | >= 1.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.107 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuredevops_serviceendpoint_azurecr.container_registry](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/serviceendpoint_azurecr) | resource |
| [azurerm_federated_identity_credential.federated_setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_role_assignment.managed_identity_default_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_resource_group.default_assignment_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azurecr_name"></a> [azurecr\_name](#input\_azurecr\_name) | ACR's name | `string` | n/a | yes |
| <a name="input_azurecr_resource_group_name"></a> [azurecr\_resource\_group\_name](#input\_azurecr\_resource\_group\_name) | Resource group name where the ACR is installed | `string` | n/a | yes |
| <a name="input_default_roleassignment_rg_prefix"></a> [default\_roleassignment\_rg\_prefix](#input\_default\_roleassignment\_rg\_prefix) | (Optional) Add a prefix to default\_roleassignment\_rg | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group where the managed identity will be create | `string` | n/a | yes |
| <a name="input_serviceendpoint_azurecr_name_prefix"></a> [serviceendpoint\_azurecr\_name\_prefix](#input\_serviceendpoint\_azurecr\_name\_prefix) | (Optional) Service connection azurerm name | `string` | `""` | no |
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
