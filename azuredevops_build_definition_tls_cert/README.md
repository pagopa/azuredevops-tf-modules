# azuredevops_build_definition_tls_cert

Module that allows:

* **pipeline**: creation with repo usually linked to <https://github.com/pagopa/le-azure-acme-tiny>
* **resource auth**: create authorization that allow to connect to (service connection already created):
  * github service connection
  * azure rm service connection (usually: `XXX-TLS-CERT-SERVICE-CONN`)
* **SP azdo-sp-acme-challenge-xxx**: that allow the python script acme_tiny.py to create a DNS record TXT on DNS to valite certificate on Let's encrypt

## Architecture

![architecture](./docs/module-arch.drawio.png)

<!-- markdownlint-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) | <= 0.10.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | <= 3.71.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azuredevops_serviceendpoint_federated"></a> [azuredevops\_serviceendpoint\_federated](#module\_azuredevops\_serviceendpoint\_federated) | git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_serviceendpoint_federated | v4.0.0 |
| <a name="module_secrets"></a> [secrets](#module\_secrets) | git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query | v6.15.2 |

## Resources

| Name | Type |
|------|------|
| [azuredevops_build_definition.pipeline](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) | resource |
| [azuredevops_resource_authorization.github_service_connection_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [azuredevops_resource_authorization.service_connection_ids_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [azurerm_role_assignment.managed_identity_default_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_pool_name"></a> [agent\_pool\_name](#input\_agent\_pool\_name) | The agent pool that should execute the build | `string` | `"Azure Pipelines"` | no |
| <a name="input_credential_key_vault_name"></a> [credential\_key\_vault\_name](#input\_credential\_key\_vault\_name) | (Required) key vault where store service principal credentials | `string` | n/a | yes |
| <a name="input_credential_key_vault_resource_group"></a> [credential\_key\_vault\_resource\_group](#input\_credential\_key\_vault\_resource\_group) | (Required) key vault resource group where store service principal credentials | `string` | n/a | yes |
| <a name="input_dns_record_name"></a> [dns\_record\_name](#input\_dns\_record\_name) | (Required) Dns record name | `string` | n/a | yes |
| <a name="input_dns_zone_name"></a> [dns\_zone\_name](#input\_dns\_zone\_name) | (Required) Dns zone name | `string` | n/a | yes |
| <a name="input_dns_zone_resource_group"></a> [dns\_zone\_resource\_group](#input\_dns\_zone\_resource\_group) | (Required) Dns zone resource group name | `string` | n/a | yes |
| <a name="input_github_service_connection_id"></a> [github\_service\_connection\_id](#input\_github\_service\_connection\_id) | (Required) GitHub service connection ID used to link Azure DevOps. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) Pipeline name equals to domain name | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | (Required) Pipeline path on Azure DevOps | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | (Required) GitHub repository attributes | <pre>object({<br>    organization   = string<br>    name           = string<br>    branch_name    = string<br>    pipelines_path = string<br>  })</pre> | n/a | yes |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | Allow to setup schedules trigger in azure devops. Usign that the schedules used in the yaml will be disabled | <pre>object({<br>    days_to_build              = list(string)<br>    schedule_only_with_changes = bool<br>    start_hours                = number<br>    start_minutes              = number<br>    time_zone                  = string<br>    branch_filter = object({<br>      include = list(string)<br>      exclude = list(string)<br>    })<br>  })</pre> | <pre>{<br>  "branch_filter": {<br>    "exclude": [],<br>    "include": [<br>      "main",<br>      "master"<br>    ]<br>  },<br>  "days_to_build": [<br>    "Mon"<br>  ],<br>  "schedule_only_with_changes": false,<br>  "start_hours": 1,<br>  "start_minutes": 0,<br>  "time_zone": "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"<br>}</pre> | no |
| <a name="input_service_connection_ids_authorization"></a> [service\_connection\_ids\_authorization](#input\_service\_connection\_ids\_authorization) | (Optional) List service connection IDs that pipeline needs authorization. github\_service\_connection\_id is authorized by default | `list(string)` | `null` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | (Required) Azure Subscription ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | (Required) Azure Subscription name related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Required) Azure Tenant ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_variables"></a> [variables](#input\_variables) | (Optional) Pipeline variables | `map(any)` | `null` | no |
| <a name="input_variables_secret"></a> [variables\_secret](#input\_variables\_secret) | (Optional) Pipeline secret variables | `map(any)` | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
