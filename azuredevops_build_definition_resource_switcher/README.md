# azuredevops_build_definition_resource_switcher

This module provides the pipeline definitions used to automatically manage the scale up/down of various resource types, based on the provided configuration.

It will create 2 pipelines for each instance of the resource configured: one to start it and one to stop it

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

locals {
  required_variables = {
      TF_AZURE_SERVICE_CONNECTION_NAME = azuredevops_serviceendpoint_azurerm.DEV-SERVICE-CONN.service_endpoint_name
      TF_AZURE_DEVOPS_POOL_AGENT_NAME: "devopslab-dev-linux"
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
    local.required_variables,
    local.some_other_variables,
  )

  variables_secret = merge(
    local.some_secret_variables,
    local.some_other_secret_variables,
  )


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
    sa_sftp = [
      {
        start_time   = "08:00"
        stop_time    = "21:00"
        sa_name = "my_storage_account_name"
      }
    ]
  }
}
```

**Provider configuration:**
For safety reasons, this pipeline should be available only on dev environment; using the provider alias for your dev environment can save you a lot of headache


**Repository configuration:**
Although you can define a custom pipeline yaml to be used by this definition, the default templates have already been defined and cofigured as default. Each resource use a specific template stored in that repository  
To use it, your `repository` configuration must be as follows:

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
- `sa_sftp`: start/stop configuration for Storage Account SFTP servers
  - `start_time`: start time, expressed in `HH:mm` format, when to start the server
  - `stop_time`: stop time, expressed in `HH:mm` format, when to stop the server
  - `sa_name`: name of the storage account on which the SFTP server should be managed

**NB:** scaling down aks clusters, the provided pipeline template will use only the `min` value configured for the field `nodes_on_stop`, but you still need to configure if using the format defined above


### Required variables for this module

| Name                               | Description                   | Example                                                                    |
|------------------------------------|-------------------------------|----------------------------------------------------------------------------|
| TF_AZURE_SERVICE_CONNECTION_NAME   | Azure service connection name | azuredevops_serviceendpoint_azurerm.DEV-SERVICE-CONN.service_endpoint_name |
| TF_AZURE_DEVOPS_POOL_AGENT_NAME    | AZ DevOps agent pool name     | devopslab-dev-linux                                                        |




### Variables passed to the pipelines

| Name                     | Description                                                     | Resource        |
|--------------------------|-----------------------------------------------------------------|-----------------|
| TF_ACTION                | Action to execute: `start, stop`                                | common          |
| TF_CLUSTER_NAME          | Name of the AKS cluster                                         | AKS             |
| TF_CLUSTER_RG            | Resource group name of the AKS cluster                          | AKS             |
| TF_USER_NODE_COUNT_MIN   | Minimum number of nodes to configure on "User" type node pool   | AKS             |
| TF_USER_NODE_COUNT_MAX   | Maximum number of nodes to configure on "User" type node pool   | AKS             |
| TF_SYSTEM_NODE_COUNT_MIN | Minimum number of nodes to configure on "System" type node pool | AKS             |
| TF_SYSTEM_NODE_COUNT_MAX | Maximum number of nodes to configure on "System" type node pool | AKS             |
| TF_SA_NAME               | Storage Account name                                            | Storage Account |



## How to handle a new resource

First of all, you need to create a new `tf` file for dedicated to the new resource, similar to `storage_account_pipeline.tf` or `aks_pipeline.tf`, in which you will:

- customize the variables passed to the pipeline template
- change the names of the resources to avoid overlapping 
- parse the scheduling configuration for your resource
- change the name of the pipeline template that will be used (`repository.yml_path`)

You also have to update the `variables.tf` to include the definition of your specific scheduling configuration

In addition, you'll have to define the pipeline template to handle your resource; in the repo `eng-common-scripts/devops` you'll find the templates that manage aks and storage account.
You'll have to create your own, customizing the parameters reading section, and the shell script which actually switches on/off the resource

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
| [azuredevops_build_definition.aks_pipeline](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) | resource |
| [azuredevops_build_definition.sa_pipeline](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition) | resource |
| [azuredevops_resource_authorization.aks_github_service_connection_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [azuredevops_resource_authorization.aks_service_connection_ids_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [azuredevops_resource_authorization.sa_github_service_connection_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [azuredevops_resource_authorization.sa_service_connection_ids_authorization](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/resource_authorization) | resource |
| [time_sleep.aks_wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sa_wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_pool_name"></a> [agent\_pool\_name](#input\_agent\_pool\_name) | The agent pool that should execute the build | `string` | `"Azure Pipelines"` | no |
| <a name="input_github_service_connection_id"></a> [github\_service\_connection\_id](#input\_github\_service\_connection\_id) | (Required) GitHub service connection ID used to link Azure DevOps. | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | (Required) Pipeline path on Azure DevOps | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) Azure DevOps project ID | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | (Required) GitHub repository attributes | <pre>object({<br>    organization    = string<br>    name            = string<br>    branch_name     = string<br>    pipelines_path  = string<br>    yml_prefix_name = string<br>  })</pre> | <pre>{<br>  "branch_name": "refs/heads/main",<br>  "name": "eng-common-scripts",<br>  "organization": "pagopa",<br>  "pipelines_path": "devops",<br>  "yml_prefix_name": null<br>}</pre> | no |
| <a name="input_schedule_configuration"></a> [schedule\_configuration](#input\_schedule\_configuration) | (Required) structure defining which service to manage, when and how. See README.md for details | <pre>object({<br>    days_to_build = list(string)<br>    timezone      = string<br>    branch_filter = object({<br>      include = list(string)<br>      exclude = list(string)<br>    })<br>    aks = list(object({<br>      cluster_name = string<br>      start_time   = string<br>      stop_time    = string<br>      rg           = string<br>      user = object({<br>        nodes_on_start = string<br>        nodes_on_stop  = string<br>      })<br>      system = object({<br>        nodes_on_start = string<br>        nodes_on_stop  = string<br>      })<br>    }))<br>    sa_sftp = list(object({<br>      start_time = string<br>      stop_time  = string<br>      sa_name    = string<br>    }))<br>  })</pre> | <pre>{<br>  "aks": [],<br>  "branch_filter": null,<br>  "days_to_build": [],<br>  "sa_sftp": [],<br>  "timezone": null<br>}</pre> | no |
| <a name="input_service_connection_ids_authorization"></a> [service\_connection\_ids\_authorization](#input\_service\_connection\_ids\_authorization) | (Optional) List service connection IDs that pipeline needs authorization. github\_service\_connection\_id is authorized by default | `list(string)` | `[]` | no |
| <a name="input_variables"></a> [variables](#input\_variables) | (Optional) Pipeline variables | `map(any)` | `null` | no |
| <a name="input_variables_secret"></a> [variables\_secret](#input\_variables\_secret) | (Optional) Pipeline secret variables | `map(any)` | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
