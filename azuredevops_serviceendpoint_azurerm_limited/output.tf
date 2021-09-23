output "service_principal_app_id" {
  value       = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).appId
  sensitive   = true
  description = "description"
}

output "service_principal_name" {
  value       = "azdo-sp-${var.name}"
  description = "description"
}

output "service_endpoint_name" {
  value       = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name
  description = "description"
}

output "service_endpoint_id" {
  value       = azuredevops_serviceendpoint_azurerm.this.id
  description = "description"
}
