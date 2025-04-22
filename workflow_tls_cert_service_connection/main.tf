module "letsencrypt" {
  # source           = "./.terraform/modules/__v3__/letsencrypt_credential"
  source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//letsencrypt_credential?ref=v8.80.0"

  count = var.letsencrypt_credential_enabled ? 1 : 0

  prefix            = var.prefix
  env               = var.env_short
  key_vault_name    = var.key_vault_name
  subscription_name = var.subscription_name
}

module "tls_cert_service_conn_federated" {
  # source              = "./.terraform/modules/__devops_v0__/azuredevops_serviceendpoint_federated"
  source = "../azuredevops_serviceendpoint_federated"
  count  = var.tls_cert_service_conn_enabled ? 1 : 0

  location            = var.location
  resource_group_name = var.identity_resource_group_name
  project_id          = var.azdo_project_id
  name                = var.identity_name
  tenant_id           = var.tenant_id
  subscription_name   = var.subscription_name
  subscription_id     = var.subscription_id
}

resource "azurerm_key_vault_access_policy" "tls_cert_service_conn_kv_access_policy" {
  count = var.tls_cert_service_conn_enabled ? 1 : 0

  key_vault_id            = var.key_vault_id
  tenant_id               = var.tenant_id
  object_id               = module.tls_cert_service_conn_federated[0].service_principal_object_id
  certificate_permissions = ["Get", "Import"]
}
