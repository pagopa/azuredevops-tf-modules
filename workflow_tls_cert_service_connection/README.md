# TLS Cert Service Connection Module

Reusable Terraform module to create:
- Federated Azure DevOps service connection
- Key Vault access policy for TLS certificates
- Let's Encrypt credential management

This module simplifies the integration of Azure DevOps with Azure Key Vault for secure TLS certificate handling and automation.
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_letsencrypt"></a> [letsencrypt](#module\_letsencrypt) | git::https://github.com/pagopa/terraform-azurerm-v3.git//letsencrypt_credential | v8.80.0 |
| <a name="module_tls_cert_service_conn_federated"></a> [tls\_cert\_service\_conn\_federated](#module\_tls\_cert\_service\_conn\_federated) | ../azuredevops_serviceendpoint_federated | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_access_policy.tls_cert_service_conn_kv_access_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azdo_project_id"></a> [azdo\_project\_id](#input\_azdo\_project\_id) | Azure DevOps project id (must be a GUID) | `string` | n/a | yes |
| <a name="input_env_short"></a> [env\_short](#input\_env\_short) | Environment (d, u, p) | `string` | n/a | yes |
| <a name="input_identity_name"></a> [identity\_name](#input\_identity\_name) | Service connection resource name | `string` | n/a | yes |
| <a name="input_identity_resource_group_name"></a> [identity\_resource\_group\_name](#input\_identity\_resource\_group\_name) | Resource group name | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Key Vault id (must be a GUID) | `string` | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Key Vault name | `string` | n/a | yes |
| <a name="input_letsencrypt_credential_enabled"></a> [letsencrypt\_credential\_enabled](#input\_letsencrypt\_credential\_enabled) | Enable letsencrypt credential | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure location | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Resource prefix | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Subscription id (must be a GUID) | `string` | n/a | yes |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | Subscription name | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Tenant id (must be a GUID) | `string` | n/a | yes |
| <a name="input_tls_cert_service_conn_enabled"></a> [tls\_cert\_service\_conn\_enabled](#input\_tls\_cert\_service\_conn\_enabled) | Enable TLS cert service connection | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_identity_app_name"></a> [identity\_app\_name](#output\_identity\_app\_name) | User Managed Identity name |
| <a name="output_identity_client_id"></a> [identity\_client\_id](#output\_identity\_client\_id) | The ID of the app associated with the Identity. |
| <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id) | The ID of the Service Principal object associated with the created Identity. |
| <a name="output_service_endpoint_id"></a> [service\_endpoint\_id](#output\_service\_endpoint\_id) | outputs.tf |
| <a name="output_service_endpoint_name"></a> [service\_endpoint\_name](#output\_service\_endpoint\_name) | n/a |
| <a name="output_service_principal_object_id"></a> [service\_principal\_object\_id](#output\_service\_principal\_object\_id) | The ID of the Service Principal object associated with the created Identity. |
<!-- END_TF_DOCS -->
