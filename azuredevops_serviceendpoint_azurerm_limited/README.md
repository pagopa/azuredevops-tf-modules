# azuredevops_serviceendpoint_azurerm_limited

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
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.10.0 |
| <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) | >= 0.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | <= 3.53.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 1.3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_secrets"></a> [secrets](#module\_secrets) | git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query | v6.15.2 |

## Resources

| Name | Type |
|------|------|
| [azuredevops_serviceendpoint_azurerm.this](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/serviceendpoint_azurerm) | resource |
| [null_resource.this](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azuread_service_principal.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_credential_key_vault_name"></a> [credential\_key\_vault\_name](#input\_credential\_key\_vault\_name) | (Required) Key vault name where store service principal credentials | `string` | n/a | yes |
| <a name="input_credential_key_vault_resource_group"></a> [credential\_key\_vault\_resource\_group](#input\_credential\_key\_vault\_resource\_group) | (Required) Key vault resource group where store service principal credentials | `string` | n/a | yes |
| <a name="input_credential_subcription"></a> [credential\_subcription](#input\_credential\_subcription) | (Required) Azure Subscription where store service principal credentials | `string` | n/a | yes |
| <a name="input_default_roleassignment_rg_prefix"></a> [default\_roleassignment\_rg\_prefix](#input\_default\_roleassignment\_rg\_prefix) | (Optional) Add a prefix to default\_roleassignment\_rg | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Service principal name | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_renew_token"></a> [renew\_token](#input\_renew\_token) | (Required) Renew token to recreate service principal. Change it to renew service principal credentials | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | (Required) Azure Subscription ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | (Required) Azure Subscription name related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Required) Azure Tenant ID related to tenant where create service principal | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_endpoint_id"></a> [service\_endpoint\_id](#output\_service\_endpoint\_id) | Service endpoint id |
| <a name="output_service_endpoint_name"></a> [service\_endpoint\_name](#output\_service\_endpoint\_name) | Service endpoint name |
| <a name="output_service_principal_app_id"></a> [service\_principal\_app\_id](#output\_service\_principal\_app\_id) | Service principal application id |
| <a name="output_service_principal_name"></a> [service\_principal\_name](#output\_service\_principal\_name) | Service principal name |
| <a name="output_service_principal_object_id"></a> [service\_principal\_object\_id](#output\_service\_principal\_object\_id) | Service principal object id |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
