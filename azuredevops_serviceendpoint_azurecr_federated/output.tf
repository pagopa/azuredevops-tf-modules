output "service_endpoint_id" {
  value       = azuredevops_serviceendpoint_azurecr.container_registry.id
  description = "Service endpoint id"
}

output "service_endpoint_name" {
  value       = azuredevops_serviceendpoint_azurecr.container_registry.service_endpoint_name
  description = "Service endpoint name"
}

output "identity_app_name" {
  value       = azurerm_user_assigned_identity.identity.name
  description = "User Managed Identity name"
}

output "identity_client_id" {
  value       = azurerm_user_assigned_identity.identity.client_id
  description = "The ID of the app associated with the Identity."
}

output "identity_principal_id" {
  value       = azurerm_user_assigned_identity.identity.principal_id
  description = "The ID of the Service Principal object associated with the created Identity."
}

output "service_principal_object_id" {
  value       = azurerm_user_assigned_identity.identity.principal_id
  description = "The ID of the Service Principal object associated with the created Identity."
}
