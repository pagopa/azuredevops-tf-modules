output "service_endpoint_id" {
  value       = azuredevops_serviceendpoint_azurerm.azurerm.id
  description = "Service endpoint id"
}

output "service_endpoint_name" {
  value       = azuredevops_serviceendpoint_azurerm.azurerm.service_endpoint_name
  description = "Service endpoint name"
}

output "identity_app_name" {
  value       = azurerm_user_assigned_identity.identity.name
  description = "User Managed Identity name"
}

output "identity_client_id" {
  value       = azurerm_user_assigned_identity.identity.client_id
  description = "User Managed Identity client id"
}

output "identity_principal_id" {
  value       = azurerm_user_assigned_identity.identity.principal_id
  description = "User Managed Identity principal id"
}
