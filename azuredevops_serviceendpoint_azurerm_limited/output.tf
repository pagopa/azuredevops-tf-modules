output "service_principal_app_id" {
  value       = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).appId
  sensitive   = true
  description = "Service principal id"
}

output "service_principal_name" {
  value       = "azdo-sp-${var.name}"
  description = "Service principal id"
}

output "service_endpoint_name" {
  value       = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name
  description = "Service endpoint name"
}

output "service_endpoint_id" {
  value       = azuredevops_serviceendpoint_azurerm.this.id
  description = "Service endpoint id"
}
