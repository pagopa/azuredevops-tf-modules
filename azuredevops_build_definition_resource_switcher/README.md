# azuredevops_build_definition_resource_switcher

This module provides the pipeline definitions used to automatically manage the scale up/down of aks node pools, based on the provided configuration

## Usage

```hcl
# defines the target project and destination folder for this pipeline
variable "my_variables" {
  default = {
    repository = {
      organization    = "pagopa"
      name            = "eng-common-scripts"
      branch_name     = "refs/heads/main"
      pipelines_path  = "devops"
      yml_prefix_name = null
    }
    pipeline = {
      path            = "<my_name>"
    }
  }
}


module "my_service_switcher" {
  source = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_build_definition_resource_switcher?ref=<ref_version>"
  path   = var.my_variables.pipeline.path
  
  providers = {
    azurerm = azurerm.dev
  }

  project_id                   = data.azuredevops_project.project.id
  repository                   = var.my_variables.repository
  github_service_connection_id = azuredevops_serviceendpoint_github.azure-devops-github-rw.id

  variables = merge(
    local.some_variables,
    local.some_other_variables,
  )

  variables_secret = merge(
    local.some_secret_variables,
    local.some_other_secret_variables,
  )

  tenant_id                           = module.secrets.values["TENANTID"].value
  subscription_id                     = module.secrets.values["DEV-SUBSCRIPTION-ID"].value

  service_connection_ids_authorization = [
    azuredevops_serviceendpoint_github.azure-devops-github-ro.id,
    azuredevops_serviceendpoint_azurerm.DEV-SERVICE-CONN.id,
  ]

  schedule_configuration = {
    days_to_build = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    timezone = "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"
    branch_filter = {
      include = ["main"]
      exclude = []
    }
    aks = [
      {
        cluster_name = "my_cluster_name"
        start_time = "15:20"
        stop_time = "15:30"
        rg = "my_rg"
        user = {
          nodes_on_start = "1,3"
          nodes_on_stop = "0,0"
        }
        system = {
          nodes_on_start = "1,3"
          nodes_on_stop = "1,1"
        }
      }
    ]
  }
}
```

**Provider configuration:**
For safety reasons, this pipeline should be available only on dev environment; using the provider alias for your dev environment can save you a lot of headache


**Repository configuration:**
Although you can define a custom pipeline yaml to be used by this definition, one has already been defined, and takes care of scaling up or down the aks clusters. To use it, your `repository` configuration must be as follows:

```hcl
repository = {
  organization    = "pagopa"
  name            = "eng-common-scripts"
  branch_name     = "refs/heads/main"
  pipelines_path  = "devops"
  yml_prefix_name = null
}
```

**Schedule configuration:**
- `days_to_build`: days in which the pipeline should be triggered
- `timezone`: timezone reference for the start and stop time
- `branch_filter`: branches on which the pipeline should operate
- `aks`: start/stop configuration for aks clusters
  - `cluster_name`: complete name of the cluster to be managed
  - `start_time`: start time, expressed in `HH:mm` format, when to scale up/start the cluster
  - `stop_time`: stop time, expressed in `HH:mm` format, when to scale down/stop the cluster
  - `rg`: resource group name of the cluster to manage
  - `user`: configuration for `user` typed node pools
    - `nodes_on_start`: minimum and maximum number of nodes to be configured in the autoscaler when the node pool is started. expressed in `<min>,<max>` format
    - `nodes_on_stop`: minimum and maximum number of nodes to be configured in the autoscaler when the node pool is stopped. expressed in `<min>,<max>` format
  - `system`: configuration for `system` typed node pools
    - `nodes_on_start`: minimum and maximum number of nodes to be configured in the autoscaler when the node pool is started. expressed in `<min>,<max>` format
    - `nodes_on_stop`: minimum and maximum number of nodes to be configured in the autoscaler when the node pool is stopped. expressed in `<min>,<max>` format. Min on system nodes must be at least 1




<!-- markdownlint-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuredevops"></a> [azuredevops](#requirement\_azuredevops) | >= 0.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | <= 3.53.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 1.3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuredevops_build_definition.pipeline](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) | resource |
| [azuredevops_resource_authorization.github_service_connection_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [azuredevops_resource_authorization.service_connection_ids_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_pool_name"></a> [agent\_pool\_name](#input\_agent\_pool\_name) | The agent pool that should execute the build | `string` | `"Azure Pipelines"` | no |
| <a name="input_github_service_connection_id"></a> [github\_service\_connection\_id](#input\_github\_service\_connection\_id) | (Required) GitHub service connection ID used to link Azure DevOps. | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | (Required) Pipeline path on Azure DevOps | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | (Required) GitHub repository attributes | <pre>object({<br>    organization    = string<br>    name            = string<br>    branch_name     = string<br>    pipelines_path  = string<br>    yml_prefix_name = string<br>  })</pre> | n/a | yes |
| <a name="input_schedule_configuration"></a> [schedule\_configuration](#input\_schedule\_configuration) | (Required) structure defining which service to manage, when and how. See README.md for details | <pre>object({<br>    days_to_build = list(string)<br>    timezone      = string<br>    branch_filter = object({<br>      include = list(string)<br>      exclude = list(string)<br>    })<br>    aks = list(object({<br>      cluster_name = string<br>      start_time   = string<br>      stop_time    = string<br>      rg           = string<br>      user = object({<br>        nodes_on_start = string<br>        nodes_on_stop  = string<br>      })<br>      system = object({<br>        nodes_on_start = string<br>        nodes_on_stop  = string<br>      })<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_service_connection_ids_authorization"></a> [service\_connection\_ids\_authorization](#input\_service\_connection\_ids\_authorization) | (Optional) List service connection IDs that pipeline needs authorization. github\_service\_connection\_id is authorized by default | `list(string)` | `null` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | (Required) Azure Subscription ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Required) Azure Tenant ID related to tenant where create service principal | `string` | n/a | yes |
| <a name="input_variables"></a> [variables](#input\_variables) | (Optional) Pipeline variables | `map(any)` | `null` | no |
| <a name="input_variables_secret"></a> [variables\_secret](#input\_variables\_secret) | (Optional) Pipeline secret variables | `map(any)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_debug"></a> [debug](#output\_debug) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
