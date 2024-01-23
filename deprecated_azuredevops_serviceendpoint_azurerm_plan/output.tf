output "application_id" {
  value       = azuread_application.plan_app.application_id
  sensitive   = true
  description = "Service principal application id"
}

output "app_name" {
  value       = local.app_name
  description = "App name"
}

output "service_principal_object_id" {
  value       = azuread_service_principal.sp_plan.object_id
  sensitive   = true
  description = "Service principal object id"
}

output "service_endpoint_name" {
  value       = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name
  description = "Service endpoint name"
}

output "service_endpoint_id" {
  value       = azuredevops_serviceendpoint_azurerm.this.id
  description = "Service endpoint id"
}
