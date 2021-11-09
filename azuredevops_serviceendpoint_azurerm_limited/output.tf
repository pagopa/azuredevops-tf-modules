output "service_principal_app_id" {
  value       = jsondecode(module.secrets.values["azdo-sp-${var.name}"].value).appId
  sensitive   = true
  description = "Service principal application id"
}

output "service_principal_object_id" {
  value       = data.azuread_service_principal.this.object_id
  sensitive   = true
  description = "Service principal object id"
}

output "service_principal_name" {
  value       = "azdo-sp-${var.name}"
  description = "Service principal name"
}

output "service_endpoint_name" {
  value       = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name
  description = "Service endpoint name"
}

output "service_endpoint_id" {
  value       = azuredevops_serviceendpoint_azurerm.this.id
  description = "Service endpoint id"
}
