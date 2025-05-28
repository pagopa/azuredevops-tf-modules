# azuredevops_build_definition_tls_cert_federated

Module for creating a AzureDevops pipeline that renews a TLS
certificate stored in Azure KeyVault with ACME on Let's Encrypt
authority.

This module manages the following resources:

* **Azure DevOps pipeline**: creation with repo usually linked to
  <https://github.com/pagopa/le-azure-acme-tiny>.
* **Azure Managed Identity with federated OIDC credentials** with
  permissions to modify a specific record in a DNS zone.  This
  identity is used for solving the ACME challenge, that consists in
  writing a TXT record on a DNS record.  The ACME challenge is solved
  bt the
  [acme_tiny.py](https://github.com/pagopa/le-azure-acme-tiny/blob/master/acme_tiny.py)
  script.
* **Azure RM service connection** for federated auth with the managed
  identity above (usually: `XXX-TLS-CERT-SERVICE-CONN`)

## Architecture

![architecture](./docs/module-arch.drawio.png)

## Migration

### v8.x

Don't use external variables:

* `KEY_VAULT_NAME`
* `CERT_NAME_EXPIRE_SECONDS`

this variables are included into the module it self

## Usage

```hcl
variable "tlscert-testit-itn-internal-devopslab-pagopa-it" {
  default = {
    repository = {
      organization   = "pagopa"
      name           = "le-azure-acme-tiny"
      branch_name    = "refs/heads/master"
      pipelines_path = "."
    }
    pipeline = {
      enable_tls_cert = true
      path            = "TLS-Certificates\\DEV"
      dns_record_name = "testit.itn.internal"
      dns_zone_name   = "devopslab.pagopa.it"
      # common variables to all pipelines
      variables = {
      }
      # common secret variables to all pipelines
      variables_secret = {
      }
    }
  }
}

locals {
  tlscert-testit-itn-internal-devopslab-pagopa-it = {
    tenant_id         = data.azurerm_client_config.current.tenant_id
    subscription_name = data.azurerm_subscriptions.dev.subscriptions[0].display_name
    subscription_id   = data.azurerm_subscriptions.dev.subscriptions[0].subscription_id
  }
  tlscert-testit-itn-internal-devopslab-pagopa-it-variables = {
    KEY_VAULT_SERVICE_CONNECTION = module.DEV-PRINTIT-TLS-CERT-SERVICE-CONN.service_endpoint_name,
  }
  tlscert-testit-itn-internal-devopslab-pagopa-it-variables_secret = {
  }
}

module "tlscert-testit-itn-internal-devopslab-pagopa-it-cert_az" {

  source = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_build_definition_tls_cert_federated?ref=fix-cert-pipeline-definition"
  count  = var.tlscert-testit-itn-internal-devopslab-pagopa-it.pipeline.enable_tls_cert == true ? 1 : 0
  providers = {
    azurerm = azurerm.dev
  }

  project_id                   = data.azuredevops_project.project.id
  repository                   = var.tlscert-testit-itn-internal-devopslab-pagopa-it.repository
  path                         = var.tlscert-testit-itn-internal-devopslab-pagopa-it.pipeline.path
  github_service_connection_id = data.azuredevops_serviceendpoint_github.github_rw.id

  dns_record_name         = var.tlscert-testit-itn-internal-devopslab-pagopa-it.pipeline.dns_record_name
  dns_zone_name           = var.tlscert-testit-itn-internal-devopslab-pagopa-it.pipeline.dns_zone_name
  dns_zone_resource_group = var.internal_devopslab_dns_private_rg_name
  tenant_id               = local.tlscert-testit-itn-internal-devopslab-pagopa-it.tenant_id
  subscription_name       = local.tlscert-testit-itn-internal-devopslab-pagopa-it.subscription_name
  subscription_id         = local.tlscert-testit-itn-internal-devopslab-pagopa-it.subscription_id
  managed_identity_resource_group_name = var.identity_rg_name

  credential_key_vault_name            = "${local.dev_domain_key_vault_name}"
  credential_key_vault_resource_group  = local.dev_domain_key_vault_resource_group
  location                = var.location

  variables = merge(
    var.tlscert-testit-itn-internal-devopslab-pagopa-it.pipeline.variables,
    local.tlscert-testit-itn-internal-devopslab-pagopa-it-variables,
  )

  variables_secret = merge(
    var.tlscert-testit-itn-internal-devopslab-pagopa-it.pipeline.variables_secret,
    local.tlscert-testit-itn-internal-devopslab-pagopa-it-variables_secret,
  )

  service_connection_ids_authorization = [
    module.DEV-PRINTIT-TLS-CERT-SERVICE-CONN.service_endpoint_id,
  ]

  schedules = {
    days_to_build              = ["Fri"]
    schedule_only_with_changes = false
    start_hours                = 3
    start_minutes              = 0
    time_zone                  = "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"
    branch_filter = {
      include = ["master"]
      exclude = []
    }
  }
}

```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) | ~> 1.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.107 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.11 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azuredevops_serviceendpoint_federated"></a> [azuredevops\_serviceendpoint\_federated](#module\_azuredevops\_serviceendpoint\_federated) | git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_serviceendpoint_federated | v9.0.0 |
| <a name="module_secrets"></a> [secrets](#module\_secrets) | git::https://github.com/pagopa/terraform-azurerm-v3.git//key_vault_secrets_query | v8.21.0 |

## Resources

| Name | Type |
|------|------|
| [azuredevops_build_definition.pipeline](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) | resource |
| [azuredevops_build_definition.pipeline_cert_diff](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) | resource |
| [azuredevops_pipeline_authorization.github_service_connection_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/pipeline_authorization) | resource |
| [azuredevops_pipeline_authorization.service_connection_ids_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/pipeline_authorization) | resource |
| [azuredevops_pipeline_authorization.service_connection_le_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/pipeline_authorization) | resource |
| [azurerm_monitor_scheduled_query_rules_alert.cert_diff_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert) | resource |
| [azurerm_role_assignment.managed_identity_default_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/application_insights) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_pool_name"></a> [agent\_pool\_name](#input\_agent\_pool\_name) | The agent pool that should execute the build | `string` | `"Azure Pipelines"` | no |
| <a name="input_cert_diff_variables"></a> [cert\_diff\_variables](#input\_cert\_diff\_variables) | (Optional) Cert diff pipeline variables | <pre>object({<br/>    enabled           = bool<br/>    alert_enabled     = bool<br/>    cert_diff_version = string<br/>    app_insights_name = optional(string)<br/>    app_insights_rg   = optional(string)<br/>    actions_group     = optional(list(string))<br/>  })</pre> | <pre>{<br/>  "alert_enabled": false,<br/>  "cert_diff_version": "0.2.5",<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_cert_name_expire_seconds"></a> [cert\_name\_expire\_seconds](#input\_cert\_name\_expire\_seconds) | (Optional) Certficate expire in seconds. Default is '2592000' #30 days | `number` | `2592000` | no |
| <a name="input_credential_key_vault_name"></a> [credential\_key\_vault\_name](#input\_credential\_key\_vault\_name) | (Required) key vault where store service principal credentials | `string` | n/a | yes |
| <a name="input_credential_key_vault_resource_group"></a> [credential\_key\_vault\_resource\_group](#input\_credential\_key\_vault\_resource\_group) | (Required) key vault resource group where store service principal credentials | `string` | n/a | yes |
| <a name="input_dns_record_name"></a> [dns\_record\_name](#input\_dns\_record\_name) | (Required) Dns record name | `string` | n/a | yes |
| <a name="input_dns_zone_name"></a> [dns\_zone\_name](#input\_dns\_zone\_name) | (Required) Dns zone name | `string` | n/a | yes |
| <a name="input_dns_zone_resource_group"></a> [dns\_zone\_resource\_group](#input\_dns\_zone\_resource\_group) | (Required) Dns zone resource group name | `string` | n/a | yes |
| <a name="input_github_service_connection_id"></a> [github\_service\_connection\_id](#input\_github\_service\_connection\_id) | (Required) GitHub service connection ID used to link Azure DevOps. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_managed_identity_resource_group_name"></a> [managed\_identity\_resource\_group\_name](#input\_managed\_identity\_resource\_group\_name) | (Required) Managed identity resource group, where will be created | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | (Required) Pipeline path on Azure DevOps | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | (Required) GitHub repository attributes | <pre>object({<br/>    organization   = string<br/>    name           = string<br/>    branch_name    = string<br/>    pipelines_path = string<br/>  })</pre> | n/a | yes |
| <a name="input_repository_repo_type"></a> [repository\_repo\_type](#input\_repository\_repo\_type) | (Optional) The repository type. Valid values: GitHub or GitHub Enterprise. Defaults to GitHub. If repo\_type is GitHubEnterprise, must use existing project and GitHub Enterprise service connection. | `string` | `"GitHub"` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | Allow to setup schedules trigger in azure devops. Usign that the schedules used in the yaml will be disabled | <pre>object({<br/>    days_to_build              = list(string)<br/>    schedule_only_with_changes = bool<br/>    start_hours                = number<br/>    start_minutes              = number<br/>    time_zone                  = string<br/>    branch_filter = object({<br/>      include = list(string)<br/>      exclude = list(string)<br/>    })<br/>  })</pre> | <pre>{<br/>  "branch_filter": {<br/>    "exclude": [],<br/>    "include": [<br/>      "main",<br/>      "master"<br/>    ]<br/>  },<br/>  "days_to_build": [<br/>    "Fri"<br/>  ],<br/>  "schedule_only_with_changes": false,<br/>  "start_hours": 1,<br/>  "start_minutes": 0,<br/>  "time_zone": "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"<br/>}</pre> | no |
| <a name="input_service_connection_ids_authorization"></a> [service\_connection\_ids\_authorization](#input\_service\_connection\_ids\_authorization) | (Optional) List service connection IDs that pipeline needs authorization. github\_service\_connection\_id is authorized by default | `list(string)` | `null` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | (Required) Azure Subscription ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | (Required) Azure Subscription name related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Required) Azure Tenant ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_variables"></a> [variables](#input\_variables) | (Optional) Pipeline variables | `map(any)` | `null` | no |
| <a name="input_variables_secret"></a> [variables\_secret](#input\_variables\_secret) | (Optional) Pipeline secret variables | `map(any)` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
